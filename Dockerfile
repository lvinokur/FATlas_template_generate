FROM BIDS-Apps/MRtrix3_connectome
MAINTAINER Lea Vinokur <lea.vinokur@gmail.com>

# Core system capabilities required
RUN apt-get update && apt-get install -y git python libeigen3-dev zlib1g-dev wget bsdtar software-properties-common

# Now that we have software-properties-common, can use add-apt-repository to get to g++ version 5, which is required by JSON for Modern C++
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update && apt-get install -y g++-5

RUN wget -O- http://neuro.debian.net/lists/trusty.au.full | tee /etc/apt/sources.list.d/neurodebian.sources.list

# Software Prerequisites
RUN apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && apt-get update

# fsl
RUN apt-get install -y ants
RUN apt-get install -y fsl-5.0-core
RUN apt-get install -y fsl-first-data

# Eddy
RUN rm -f `which eddy`
RUN mkdir /opt/eddy/
RUN wget -qO- https://fsl.fmrib.ox.ac.uk/fsldownloads/patches/eddy-patch-fsl-5.0.9/centos6/eddy_openmp > /opt/eddy/eddy_openmp
RUN wget -qO- https://fsl.fmrib.ox.ac.uk/fsldownloads/patches/eddy-patch-fsl-5.0.9/centos6/eddy_cuda7.5 > /opt/eddy/eddy_cuda
RUN chmod 775 /opt/eddy/eddy_openmp
RUN chmod 775 /opt/eddy/eddy_cuda

# Unring
RUN wget -qO- https://bitbucket.org/reisert/unring/get/8e5eeba67a1d.zip -O unring.zip && unzip -qq -o unring.zip -d /opt/ && rm -f unring.zip

#HCP Pipelines other prerequisites:
RUN apt-get install connectome-workbench
RUN apt-get install python-numpy
RUN apt-get install python-scipy
RUN pip install nibabel
RUN git clone https://github.com/Washington-University/gradunwarp.git $$ cd gradunwarp $$ git checkout v1.0.3 $$ python setup.py install

#Pipelines

RUN git clone https://github.com/Washington-University/Pipelines.git $$ cd Pipelines $ git checkout v3.22.0

ENV CXX=/usr/bin/g++-5

#MRtrix3 setup
RUN git clone https://github.com/MRtrix3/mrtrix3.git mrtrix3 && cd mrtrix3 && git checkout 3.0_RC2 && python configure -nogui && NUMBER_OF_PROCESSORS=1 python build
RUN echo $'FailOnWarn: 1\n' > /etc/mrtrix.conf
RUN if [ "$CIRCLECI" = "true" ]; then cd mrtrix3 && NUMBER_OF_PROCESSORS=1 python build; else cd mrtrix3 && python build; fi






# Environment variables setup
ENV FSLDIR=/usr/share/fsl/5.0
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV PATH=/usr/lib/fsl/5.0:$PATH
ENV PATH=/usr/lib/ants/:$PATH
ENV PATH=/mrtrix3/release/bin:$PATH
ENV PATH=/mrtrix3/scripts:$PATH
ENV FSLMULTIFILEQUIT=TRUE
ENV LD_LIBRARY_PATH=/usr/lib/fsl/5.0
ENV PYTHONPATH=/mrtrix3/scripts:$PYTHONPATH

RUN mkdir /bids_input
RUN mkdir /output
COPY run.py /code/run.py
RUN chmod 775 /run.py


COPY version /version

ENTRYPOINT ["/code/run.py"]
