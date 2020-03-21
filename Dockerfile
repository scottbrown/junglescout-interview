FROM node:13.10.1
MAINTAINER Scott

# Create space for the app installation
RUN mkdir /app

# Add the code from this repository
ADD . /app

# TODO: see if lower privs works
RUN useradd -ms /bin/bash svc

# Run the container out of the install directory
WORKDIR /app

# Install dependencies
RUN npm install

# Start the server
USER svc
CMD node server.js
