CREATE SEQUENCE etablissement_id_seq START 1;

CREATE TYPE Tpourcentage AS (

                                id integer,
                                Dont_effectif_des_admis_issus_de_la_même_académie float,
                                Dont_effectif_des_admis_néo_bacheliers_sans_mention_au_bac float,
                                Dont_effectif_des_candidates_pour_une_formation float

                            );

CREATE TYPE Tformation AS (
                              id integer,
                              annee_session INT,
                              nom_etab VARCHAR(1000),
                              capacite_formation INT,
                              filiere_detaillee VARCHAR(1000),
                              filiere_formation VARCHAR(1000),
                              pourcentage Tpourcentage
                          );

CREATE TYPE Tetablissement AS (
                 id integer,
                 code_uai VARCHAR(1000),
                 nom_etablissement VARCHAR(1000),
                 code_departement INT,
                 nom_departement VARCHAR(1000),
                 region VARCHAR(1000),
                 formations Tformation[]

                                       );



create table etablissements of Tetablissement(
    id primary key DEFAULT nextval('etablissement_id_seq'::regclass)
);
create table formations of Tformation(
    id primary key
);
create table pourcentages of Tpourcentage(
    id primary key
);

CREATE OR REPLACE FUNCTION inserts()
    RETURNS VOID AS $$
DECLARE
    cur_data CURSOR FOR SELECT * FROM "fr-esr-parcoursup";
    data "fr-esr-parcoursup"%ROWTYPE;
    i integer;
    cur_etab CURSOR FOR SELECT * FROM etablissements;
    row_etab etablissements%ROWTYPE;
BEGIN

    DELETE FROM pourcentages where 1 =1;
    DELETE FROM formations where 1 =1;
    DELETE FROM etablissements where 1 =1;

    OPEN cur_data;
    i=1;
    LOOP
        FETCH cur_data INTO data;
        EXIT WHEN NOT FOUND;

        INSERT INTO pourcentages(id,
                                 Dont_effectif_des_admis_issus_de_la_même_académie ,
                                 Dont_effectif_des_admis_néo_bacheliers_sans_mention_au_bac ,
                                 Dont_effectif_des_candidates_pour_une_formation )
        VALUES (i,
                data."Dont effectif des admis issus de la même académie",
                data."Dont effectif des admis néo bacheliers sans mention au bac",
                data."Dont effectif des candidates pour une formation"
               );

        INSERT INTO formations
        VALUES (i, data."Session", data."Établissement", data."Capacité de l’établissement par formation", data."Filière de formation détaillée", data."Filière de formation", (SELECT (id,
                                                                                               Dont_effectif_des_admis_issus_de_la_même_académie ,
                                                                                               Dont_effectif_des_admis_néo_bacheliers_sans_mention_au_bac ,
                                                                                               Dont_effectif_des_candidates_pour_une_formation)::Tpourcentage FROM pourcentages p WHERE p.id = i));

        i = i + 1;
    END LOOP;

    INSERT INTO etablissements(code_uai,
                               nom_etablissement,
                               code_departement,
                               nom_departement,
                               region) (SELECT DISTINCT "Code UAI de l'établissement" , "Établissement", "Code départemental de l’établissement", "Département de l’établissement", "Région de l’établissement" FROM "fr-esr-parcoursup" f);

    OPEN cur_etab;

    LOOP
        FETCH cur_etab INTO row_etab;
        EXIT WHEN NOT FOUND;
        UPDATE etablissements
        SET
            formations = ARRAY(SELECT ROW(id, annee_session,nom_etab,
                                          capacite_formation ,
                                          filiere_detaillee ,
                                          filiere_formation ,
                                          pourcentage)::TFormation
                               FROM formations f
                               WHERE f.nom_etab = row_etab."nom_etablissement")
        WHERE
                id = row_etab."id";

    END LOOP;

    CLOSE cur_etab;
    CLOSE cur_data;

END
$$ LANGUAGE plpgsql;

select inserts();





select * from etablissements;

--selectionner pourcentage de candidats pour une formation à l'université du havre
SELECT (unnest(e.formations)).annee_session,(unnest(e.formations)).filiere_formation, (unnest(e.formations)).pourcentage
FROM etablissements e
where e.nom_etablissement= 'Nantes Université';

-- selectionner les formations existantes dans le departement Isère
select e.nom_departement, e.nom_etablissement , (unnest(e.formations)).filiere_formation
FROM etablissements e
where e.nom_departement = 'Isère';

