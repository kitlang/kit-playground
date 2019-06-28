FROM ubuntu:18.04
MAINTAINER ben@bendmorris.com

# installation/environment setup
WORKDIR /app
ENV PATH="/root/.local/bin:${PATH}"
ENV KIT_STD_PATH=/opt/kit/std
ENV KIT_TOOLCHAIN_PATH=/opt/kit/toolchains
RUN apt-get update && apt-get install -y ghc haskell-stack python-pip git openjdk-8-jre cmake && apt-get clean
RUN stack upgrade
# install Emscripten
RUN git clone https://github.com/emscripten-core/emsdk.git /opt/emsdk
RUN cd /opt/emsdk && ./emsdk install latest && ./emsdk activate latest
# install Kit
RUN git clone https://github.com/kitlang/kit /opt/kit
RUN cd /opt/kit && git checkout dev && stack install kitlang:kitc
# compile a test program to force Emscripten to generate system libraries
RUN bash -c "source /opt/emsdk/emsdk_env.sh && echo \"function main() { puts('hi'); }\" > /tmp/test.kit && kitc --host emscripten /tmp/test.kit -o /tmp/test.js"
# set up the playground
ADD requirements.txt /app/
RUN pip install -r requirements.txt
ADD playground.py /app/
EXPOSE 5000

CMD ["/bin/bash", "-c", "source /opt/emsdk/emsdk_env.sh && python playground.py"]
