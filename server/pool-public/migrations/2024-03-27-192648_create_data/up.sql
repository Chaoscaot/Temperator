create table Datapoints
(
    time       timestamp not null,
    humidity   float     not null,
    air_temp   float     not null,
    water_temp float     not null,
    constraint table_name_pk
        primary key (time)
);