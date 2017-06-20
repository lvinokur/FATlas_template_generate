FROM BIDS-Apps/MRtrix3_connectome
MAINTAINER Lea Vinokur <lea.vinokur@gmail.com>

# Core system capabilities required
RUN apt-get update && apt-get install -y git python libeigen3-dev zlib1g-dev wget bsdtar software-properties-common

# Now that we have software-properties-common, can use add-apt-repository to get to g++ version 5, which is required by JSON for Modern C++
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update && apt-get install -y g++-5

RUN wget -O- http://neuro.debian.net/lists/trusty.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install fsl-5.0-eddy-nonfree ants

ENV CXX=/usr/bin/g++-5

#MRtrix3 setup
RUN git clone https://github.com/MRtrix3/mrtrix3.git mrtrix3 && cd mrtrix3 && git checkout 3.0_RC1 && python configure -nogui && NUMBER_OF_PROCESSORS=1 python build
RUN echo $'FailOnWarn: 1\n' > /etc/mrtrix.conf
RUN if [ "$CIRCLECI" = "true" ]; then cd mrtrix3 && NUMBER_OF_PROCESSORS=1 python build; else cd mrtrix3 && python build; fi

#Neurodebian and ANTS
RUN wget -O- http://neuro.debian.net/lists/trusty.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && apt-get update
RUN apt-get install -y ants

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
