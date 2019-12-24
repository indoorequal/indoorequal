-- Start a transaction.
BEGIN;
SELECT plan(9);

SELECT is(
    repeat_on_to_array('1'),
    ARRAY[ '1' ]
);


SELECT is(
    repeat_on_to_array('1.5'),
    ARRAY[ '1.5' ]
);

SELECT is(
    repeat_on_to_array('-1'),
    ARRAY[ '-1' ]
);

SELECT is(
    repeat_on_to_array('1;2'),
    ARRAY[ '1', '2' ]
);

SELECT is(
    repeat_on_to_array('1.5;2.5'),
    ARRAY[ '1.5', '2.5' ]
);

SELECT is(
    repeat_on_to_array('1-3'),
    ARRAY[ '1', '2', '3' ]
);

SELECT is(
    repeat_on_to_array('-3--1'),
    ARRAY[ '-3', '-2', '-1' ]
);

SELECT is(
    repeat_on_to_array('1-3;5'),
    ARRAY[ '1', '2', '3', '5' ]
);

SELECT is(
    repeat_on_to_array('-1-3;5'),
    ARRAY[ '-1', '0', '1', '2', '3', '5' ]
);

SELECT * FROM finish();
ROLLBACK;
