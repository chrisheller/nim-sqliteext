.load examples/libhello_world
CREATE TABLE testing(id INTEGER PRIMARY KEY, name STRING);
insert into testing values (1, 'Alice'), (2, 'Bob');
select id, helloFunc(name, id), goodbyeFunc(name), numberFunc(name) from testing;
