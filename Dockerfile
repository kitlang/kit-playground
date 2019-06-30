FROM alpine:3.10
MAINTAINER ben@bendmorris.com

# installation/environment setup
ARG TAG=dev
WORKDIR /app
ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"
ENV KIT_STD_PATH=/opt/kit/std
ENV KIT_TOOLCHAIN_PATH=/opt/kit/toolchains
RUN apk add bash cmake curl emscripten gcc ghc git make musl-dev openjdk11-jre py2-pip zlib-dev --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
# haskell stack
RUN curl -sSL https://get.haskellstack.org/ | sh
# install Emscripten
# RUN git clone https://github.com/emscripten-core/emsdk.git /opt/emsdk && \
#     cd /opt/emsdk && \
#     ./emsdk install latest && \
#     ./emsdk activate latest
# install Kit
RUN git clone https://github.com/kitlang/kit /opt/kit && \
    cd /opt/kit && \
    git checkout ${TAG} && \
    stack install kitlang:kitc --system-ghc
# compile a test program to force Emscripten to generate system libraries;
# otherwise this could cause playground requests to time out while they're
# generated
RUN echo "function main() { puts('hi'); }" > /tmp/test.kit && \
    kitc --build-dir /tmp/build --host emscripten --build none /tmp/test.kit -o /tmp/test.js
# set up the playground
ADD requirements.txt /app/
RUN pip install -r requirements.txt
ADD playground.py /app/
EXPOSE 5000

CMD ["python", "playground.py"]
