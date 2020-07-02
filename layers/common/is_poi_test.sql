BEGIN;
SELECT plan(9);

SELECT ok(
    is_poi('shop=>supermarket'::hstore)
);

SELECT ok(
    is_poi('amenity=>car_rental'::hstore)
);

SELECT ok(
    is_poi('craft=>caterer'::hstore)
);

SELECT ok(
    is_poi('leisure=>pitch'::hstore)
);

SELECT ok(
    is_poi('office=>company'::hstore)
);

SELECT ok(
    is_poi('sport=>boules'::hstore)
);

SELECT ok(
    is_poi('tourism=>hotel'::hstore)
);

SELECT ok(
    is_poi('exhibit=>artwork'::hstore)
);

SELECT ok(
    is_poi(''::hstore) = FALSE
);

SELECT * FROM finish();
ROLLBACK;
