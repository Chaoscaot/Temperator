FROM rust:slim
WORKDIR /usr/src/pool

RUN apt-get update  && apt-get install -y default-libmysqlclient-dev && rm -rf /var/lib/apt/lists/*

COPY ./pool-public/Cargo.toml ./pool-public/Cargo.toml
COPY ./pool-shared/Cargo.toml ./pool-shared/Cargo.toml
COPY ./pool-private/Cargo.toml ./pool-private/Cargo.toml
COPY ./Cargo.toml ./Cargo.toml
COPY ./pool-public/src/main.rs ./pool-public/src/main.rs
COPY ./pool-shared/src/lib.rs ./pool-shared/src/lib.rs
COPY ./pool-private/src/main.rs ./pool-private/src/main.rs

WORKDIR /usr/src/pool/pool-public

RUN cargo fetch

WORKDIR /usr/src/pool

COPY . .

WORKDIR /usr/src/pool/pool-public

RUN cargo install --path .

EXPOSE 3000

ENV DATABASE_URL=mysql://root:password@172.17.0.2:3306/pool
ENV API_HOST=0.0.0.0:3000

CMD ["pool-public"]