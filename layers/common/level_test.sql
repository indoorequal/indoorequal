BEGIN;
SELECT plan(6);

SELECT is(
    expand_levels('1', ''),
    ARRAY[ 1 ]::numeric[]
);

SELECT is(
    expand_levels('1;2', ''),
    ARRAY[ 1, 2 ]::numeric[]
);

SELECT is(
    expand_levels('1-3', ''),
    ARRAY[ 1, 2, 3 ]::numeric[]
);

SELECT is(
    expand_levels('1', '2'),
    ARRAY[ 1, 2 ]::numeric[]
);

SELECT is(
    expand_levels('1', '2;3'),
    ARRAY[ 1, 2, 3 ]::numeric[]
);

SELECT is(
    expand_levels('1', '2-4'),
    ARRAY[ 1, 2, 3, 4 ]::numeric[]
);

SELECT * FROM finish();
ROLLBACK;
