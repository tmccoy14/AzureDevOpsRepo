# BUILD environment
FROM node:10-alpine as builder

ARG REACT_APP_ENV
ENV REACT_APP_ENV=${REACT_APP_ENV}

# Create app directory
WORKDIR /usr/src/app

# Copy source into builder's working dir
COPY . ./

# Install dependencies
RUN npm install

RUN npm rebuild node-sass

# Build
RUN npm run build

# PRODUCTION environment
FROM nginx:1.16.0-alpine

# Copy files from builder, expose port, start server
COPY --from=builder /usr/src/app/build /usr/share/nginx/html
COPY --from=builder /usr/src/app/nginx/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]