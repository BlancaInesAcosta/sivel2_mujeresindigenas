--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: es_co_utf_8; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION es_co_utf_8 (lc_collate = 'es_CO.UTF-8', lc_ctype = 'es_CO.UTF-8');


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: soundexesp(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION soundexesp(input text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT COST 500
    AS $$
DECLARE
	soundex text='';	
	-- para determinar la primera letra
	pri_letra text;
	resto text;
	sustituida text ='';
	-- para quitar adyacentes
	anterior text;
	actual text;
	corregido text;
BEGIN
       -- devolver null si recibi un string en blanco o con espacios en blanco
	IF length(trim(input))= 0 then
		RETURN NULL;
	end IF;
 
 
	-- 1: LIMPIEZA:
		-- pasar a mayuscula, eliminar la letra "H" inicial, los acentos y la enie
		-- 'holá coñó' => 'OLA CONO'
		input=translate(ltrim(trim(upper(input)),'H'),'ÑÁÉÍÓÚÀÈÌÒÙÜ','NAEIOUAEIOUU');
 
		-- eliminar caracteres no alfabéticos (números, símbolos como &,%,",*,!,+, etc.
		input=regexp_replace(input, '[^a-zA-Z]', '', 'g');
 
	-- 2: PRIMERA LETRA ES IMPORTANTE, DEBO ASOCIAR LAS SIMILARES
	--  'vaca' se convierte en 'baca'  y 'zapote' se convierte en 'sapote'
	-- un fenomeno importante es GE y GI se vuelven JE y JI; CA se vuelve KA, etc
	pri_letra =substr(input,1,1);
	resto =substr(input,2);
	CASE 
		when pri_letra IN ('V') then
			sustituida='B';
		when pri_letra IN ('Z','X') then
			sustituida='S';
		when pri_letra IN ('G') AND substr(input,2,1) IN ('E','I') then
			sustituida='J';
		when pri_letra IN('C') AND substr(input,2,1) NOT IN ('H','E','I') then
			sustituida='K';
		else
			sustituida=pri_letra;
 
	end case;
	--corregir el parametro con las consonantes sustituidas:
	input=sustituida || resto;		
 
	-- 3: corregir "letras compuestas" y volverlas una sola
	input=REPLACE(input,'CH','V');
	input=REPLACE(input,'QU','K');
	input=REPLACE(input,'LL','J');
	input=REPLACE(input,'CE','S');
	input=REPLACE(input,'CI','S');
	input=REPLACE(input,'YA','J');
	input=REPLACE(input,'YE','J');
	input=REPLACE(input,'YI','J');
	input=REPLACE(input,'YO','J');
	input=REPLACE(input,'YU','J');
	input=REPLACE(input,'GE','J');
	input=REPLACE(input,'GI','J');
	input=REPLACE(input,'NY','N');
	-- para debug:    --return input;
 
	-- EMPIEZA EL CALCULO DEL SOUNDEX
	-- 4: OBTENER PRIMERA letra
	pri_letra=substr(input,1,1);
 
	-- 5: retener el resto del string
	resto=substr(input,2);
 
	--6: en el resto del string, quitar vocales y vocales fonéticas
	resto=translate(resto,'@AEIOUHWY','@');
 
	--7: convertir las letras foneticamente equivalentes a numeros  (esto hace que B sea equivalente a V, C con S y Z, etc.)
	resto=translate(resto, 'BPFVCGKSXZDTLMNRQJ', '111122222233455677');
	-- así va quedando la cosa
	soundex=pri_letra || resto;
 
	--8: eliminar números iguales adyacentes (A11233 se vuelve A123)
	anterior=substr(soundex,1,1);
	corregido=anterior;
 
	FOR i IN 2 .. length(soundex) LOOP
		actual = substr(soundex, i, 1);
		IF actual <> anterior THEN
			corregido=corregido || actual;
			anterior=actual;			
		END IF;
	END LOOP;
	-- así va la cosa
	soundex=corregido;
 
	-- 9: siempre retornar un string de 4 posiciones
	soundex=rpad(soundex,4,'0');
	soundex=substr(soundex,1,4);		
 
	-- YA ESTUVO
	RETURN soundex;	
END;	
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acompanamiento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE acompanamiento (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(500),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: acompanamiento_casosjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE acompanamiento_casosjr (
    acompanamiento_id integer NOT NULL,
    sivel2_sjr_casosjr_id integer NOT NULL
);


--
-- Name: acompanamiento_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE acompanamiento_evento (
    acompanamiento_id integer NOT NULL,
    evento_id integer NOT NULL
);


--
-- Name: acompanamiento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE acompanamiento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acompanamiento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE acompanamiento_id_seq OWNED BY acompanamiento.id;


--
-- Name: acompanamientorec_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE acompanamientorec_evento (
    acompanamiento_id integer NOT NULL,
    evento_id integer NOT NULL
);


--
-- Name: acto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE acto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actoevento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE actoevento (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    presponsable_id integer NOT NULL,
    categoria_id integer NOT NULL
);


--
-- Name: actoevento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE actoevento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actoevento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE actoevento_id_seq OWNED BY actoevento.id;


--
-- Name: anexo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE anexo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: aspsicosocial_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE aspsicosocial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aspsicosocial; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE aspsicosocial (
    id integer DEFAULT nextval('aspsicosocial_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT aspsicosocial_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: aspsicosocial_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE aspsicosocial_respuesta (
    id_respuesta integer NOT NULL,
    id_aspsicosocial integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caso_etiqueta_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caso_etiqueta_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caso_presponsable_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caso_presponsable_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: casosjr_estadocaso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE casosjr_estadocaso (
    estadocaso_id integer NOT NULL,
    sivel2_sjr_casosjr_id integer NOT NULL
);


--
-- Name: categoria_eventopresponsable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE categoria_eventopresponsable (
    categoria_id integer NOT NULL,
    eventopresponsable_id integer NOT NULL
);


--
-- Name: sivel2_gen_caso_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_caso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_caso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso (
    id integer DEFAULT nextval('sivel2_gen_caso_id_seq'::regclass) NOT NULL,
    titulo character varying(50),
    fecha date NOT NULL,
    hora character varying(10),
    duracion character varying(10),
    memo text NOT NULL,
    grconfiabilidad character varying(5),
    gresclarecimiento character varying(5),
    grimpunidad character varying(5),
    grinformacion character varying(5),
    bienes text,
    id_intervalo integer DEFAULT 5,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: victima_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE victima_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_victima; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_victima (
    id_persona integer NOT NULL,
    id_caso integer NOT NULL,
    hijos integer,
    id_profesion integer DEFAULT 22 NOT NULL,
    id_rangoedad integer DEFAULT 6 NOT NULL,
    id_filiacion integer DEFAULT 10 NOT NULL,
    id_sectorsocial integer DEFAULT 15 NOT NULL,
    id_organizacion integer DEFAULT 16 NOT NULL,
    id_vinculoestado integer DEFAULT 38 NOT NULL,
    organizacionarmada integer DEFAULT 35 NOT NULL,
    anotaciones character varying(1000),
    id_etnia integer DEFAULT 1,
    id_iglesia integer DEFAULT 1,
    orientacionsexual character(1) DEFAULT 'H'::bpchar NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('victima_seq'::regclass) NOT NULL,
    CONSTRAINT victima_hijos_check CHECK (((hijos IS NULL) OR ((hijos >= 0) AND (hijos <= 100)))),
    CONSTRAINT victima_orientacionsexual_check CHECK (((orientacionsexual = 'L'::bpchar) OR (orientacionsexual = 'G'::bpchar) OR (orientacionsexual = 'B'::bpchar) OR (orientacionsexual = 'T'::bpchar) OR (orientacionsexual = 'I'::bpchar) OR (orientacionsexual = 'H'::bpchar)))
);


--
-- Name: sivel2_sjr_casosjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_casosjr (
    id_caso integer NOT NULL,
    fecharec date NOT NULL,
    asesor integer NOT NULL,
    oficina_id integer DEFAULT 1,
    direccion character varying(1000),
    telefono character varying(1000),
    contacto integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    dependen integer,
    sustento character varying(1000),
    leerescribir boolean,
    trabaja boolean,
    ingresomensual integer,
    gastos integer,
    estrato character(1),
    id_statusmigratorio integer DEFAULT 0,
    id_proteccion integer DEFAULT 0,
    consentimientosjr boolean,
    consentimientobd boolean,
    fechasalida date,
    id_salida integer,
    fechallegada date,
    id_llegada integer,
    categoriaref integer,
    observacionesref character varying(5000),
    comosupo_id integer DEFAULT 1,
    consentimiento character varying(1) DEFAULT 'I'::character varying,
    docterrenopor character varying(512),
    consecorg character varying(16)
);


--
-- Name: cben1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW cben1 AS
 SELECT caso.id AS id_caso,
    victima.id_persona,
        CASE
            WHEN (casosjr.contacto = victima.id_persona) THEN 1
            ELSE 0
        END AS contacto,
        CASE
            WHEN (casosjr.contacto <> victima.id_persona) THEN 1
            ELSE 0
        END AS beneficiario,
    1 AS npersona,
    'total'::text AS total
   FROM sivel2_gen_caso caso,
    sivel2_sjr_casosjr casosjr,
    sivel2_gen_victima victima
  WHERE ((caso.id = victima.id_caso) AND (caso.id = casosjr.id_caso) AND (caso.id = victima.id_caso));


--
-- Name: desplazamiento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE desplazamiento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_clase_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_clase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_clase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_clase (
    id_clalocal integer,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    id_tclase character varying(10) DEFAULT 'CP'::character varying NOT NULL,
    latitud double precision,
    longitud double precision,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_municipio integer,
    id integer DEFAULT nextval('sip_clase_id_seq'::regclass) NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT clase_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_departamento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_departamento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_departamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_departamento (
    id_deplocal integer,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    latitud double precision,
    longitud double precision,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_pais integer DEFAULT 0 NOT NULL,
    id integer DEFAULT nextval('sip_departamento_id_seq'::regclass) NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT departamento_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_municipio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_municipio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_municipio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_municipio (
    id_munlocal integer,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    latitud double precision,
    longitud double precision,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_departamento integer,
    id integer DEFAULT nextval('sip_municipio_id_seq'::regclass) NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT municipio_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_ubicacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_ubicacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_ubicacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_ubicacion (
    id integer DEFAULT nextval('sip_ubicacion_id_seq'::regclass) NOT NULL,
    lugar character varying(500) COLLATE public.es_co_utf_8,
    sitio character varying(500) COLLATE public.es_co_utf_8,
    id_tsitio integer DEFAULT 1 NOT NULL,
    id_caso integer NOT NULL,
    latitud double precision,
    longitud double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_pais integer DEFAULT 0,
    id_departamento integer,
    id_municipio integer,
    id_clase integer
);


--
-- Name: sivel2_sjr_desplazamiento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_desplazamiento (
    id_caso integer NOT NULL,
    fechaexpulsion date NOT NULL,
    id_expulsion integer NOT NULL,
    fechallegada date NOT NULL,
    id_llegada integer NOT NULL,
    id_clasifdesp integer DEFAULT 0 NOT NULL,
    id_tipodesp integer DEFAULT 0 NOT NULL,
    descripcion character varying(5000),
    otrosdatos character varying(1000),
    declaro character(1),
    hechosdeclarados character varying(5000),
    fechadeclaracion date,
    departamentodecl integer,
    municipiodecl integer,
    id_declaroante integer DEFAULT 0,
    id_inclusion integer DEFAULT 0,
    id_acreditacion integer DEFAULT 0,
    retornado boolean,
    reubicado boolean,
    connacionalretorno boolean,
    acompestado boolean,
    connacionaldeportado boolean,
    oficioantes character varying(5000),
    id_modalidadtierra integer DEFAULT 0,
    materialesperdidos character varying(5000),
    inmaterialesperdidos character varying(5000),
    protegiorupta boolean,
    documentostierra character varying(5000),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    paisdecl integer,
    id integer DEFAULT nextval('desplazamiento_seq'::regclass) NOT NULL,
    CONSTRAINT desplazamiento_declaro_check CHECK (((declaro = 'S'::bpchar) OR (declaro = 'N'::bpchar) OR (declaro = 'R'::bpchar)))
);


--
-- Name: ultimodesplazamiento; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ultimodesplazamiento AS
 SELECT sivel2_sjr_desplazamiento.id,
    s.id_caso,
    s.fechaexpulsion,
    sivel2_sjr_desplazamiento.id_expulsion
   FROM sivel2_sjr_desplazamiento,
    ( SELECT sivel2_sjr_desplazamiento_1.id_caso,
            max(sivel2_sjr_desplazamiento_1.fechaexpulsion) AS fechaexpulsion
           FROM sivel2_sjr_desplazamiento sivel2_sjr_desplazamiento_1
          GROUP BY sivel2_sjr_desplazamiento_1.id_caso) s
  WHERE ((sivel2_sjr_desplazamiento.id_caso = s.id_caso) AND (sivel2_sjr_desplazamiento.fechaexpulsion = s.fechaexpulsion));


--
-- Name: cben2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW cben2 AS
 SELECT cben1.id_caso,
    cben1.id_persona,
    cben1.contacto,
    cben1.beneficiario,
    cben1.npersona,
    cben1.total,
    ubicacion.id_departamento,
    departamento.nombre AS departamento_nombre,
    ubicacion.id_municipio,
    municipio.nombre AS municipio_nombre,
    ubicacion.id_clase,
    clase.nombre AS clase_nombre,
    ultimodesplazamiento.fechaexpulsion
   FROM (((((cben1
     LEFT JOIN ultimodesplazamiento ON ((cben1.id_caso = ultimodesplazamiento.id_caso)))
     LEFT JOIN sip_ubicacion ubicacion ON ((ultimodesplazamiento.id_expulsion = ubicacion.id)))
     LEFT JOIN sip_departamento departamento ON ((ubicacion.id_departamento = departamento.id)))
     LEFT JOIN sip_municipio municipio ON ((ubicacion.id_municipio = municipio.id)))
     LEFT JOIN sip_clase clase ON ((ubicacion.id_clase = clase.id)));


--
-- Name: consecuenciafamiliar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciafamiliar (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: consecuenciafamiliar_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciafamiliar_evento (
    consecuenciafamiliar_id integer NOT NULL,
    evento_id integer NOT NULL
);


--
-- Name: consecuenciafamiliar_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consecuenciafamiliar_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consecuenciafamiliar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consecuenciafamiliar_id_seq OWNED BY consecuenciafamiliar.id;


--
-- Name: consecuenciafisica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciafisica (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: consecuenciafisica_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciafisica_evento (
    consecuenciafisica_id integer NOT NULL,
    evento_id integer NOT NULL
);


--
-- Name: consecuenciafisica_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consecuenciafisica_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consecuenciafisica_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consecuenciafisica_id_seq OWNED BY consecuenciafisica.id;


--
-- Name: consecuenciaindividual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciaindividual (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: consecuenciaindividual_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consecuenciaindividual_evento (
    consecuenciaindividual_id integer NOT NULL,
    evento_id integer NOT NULL
);


--
-- Name: consecuenciaindividual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consecuenciaindividual_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consecuenciaindividual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consecuenciaindividual_id_seq OWNED BY consecuenciaindividual.id;


--
-- Name: contexto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contexto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad (
    id integer NOT NULL,
    minutos integer,
    nombre character varying(500),
    objetivo character varying(5000),
    resultado character varying(5000),
    fecha date,
    observaciones character varying(5000),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    oficina_id integer NOT NULL,
    rangoedadac_id integer,
    usuario_id integer,
    lugar character varying(500)
);


--
-- Name: cor1440_gen_actividad_actividadtipo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_actividadtipo (
    actividad_id integer,
    actividadtipo_id integer
);


--
-- Name: cor1440_gen_actividad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividad_id_seq OWNED BY cor1440_gen_actividad.id;


--
-- Name: cor1440_gen_actividad_proyecto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_proyecto (
    id integer NOT NULL,
    actividad_id integer,
    proyecto_id integer
);


--
-- Name: cor1440_gen_actividad_proyecto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividad_proyecto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividad_proyecto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividad_proyecto_id_seq OWNED BY cor1440_gen_actividad_proyecto.id;


--
-- Name: cor1440_gen_actividad_proyectofinanciero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_proyectofinanciero (
    actividad_id integer NOT NULL,
    proyectofinanciero_id integer NOT NULL
);


--
-- Name: cor1440_gen_actividad_rangoedadac; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_rangoedadac (
    id integer NOT NULL,
    actividad_id integer,
    rangoedadac_id integer,
    ml integer,
    mr integer,
    fl integer,
    fr integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cor1440_gen_actividad_rangoedadac_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividad_rangoedadac_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividad_rangoedadac_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividad_rangoedadac_id_seq OWNED BY cor1440_gen_actividad_rangoedadac.id;


--
-- Name: cor1440_gen_actividad_sip_anexo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividad_sip_anexo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividad_sip_anexo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_sip_anexo (
    actividad_id integer NOT NULL,
    anexo_id integer NOT NULL,
    id integer DEFAULT nextval('cor1440_gen_actividad_sip_anexo_id_seq'::regclass) NOT NULL
);


--
-- Name: cor1440_gen_actividad_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividad_usuario (
    actividad_id integer NOT NULL,
    usuario_id integer NOT NULL
);


--
-- Name: cor1440_gen_actividadarea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividadarea (
    id integer NOT NULL,
    nombre character varying(500),
    observaciones character varying(5000),
    fechacreacion date DEFAULT ('now'::text)::date,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cor1440_gen_actividadarea_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividadarea_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividadarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividadarea_id_seq OWNED BY cor1440_gen_actividadarea.id;


--
-- Name: cor1440_gen_actividadareas_actividad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividadareas_actividad (
    id integer NOT NULL,
    actividad_id integer,
    actividadarea_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cor1440_gen_actividadareas_actividad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividadareas_actividad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividadareas_actividad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividadareas_actividad_id_seq OWNED BY cor1440_gen_actividadareas_actividad.id;


--
-- Name: cor1440_gen_actividadtipo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_actividadtipo (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cor1440_gen_actividadtipo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_actividadtipo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_actividadtipo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_actividadtipo_id_seq OWNED BY cor1440_gen_actividadtipo.id;


--
-- Name: cor1440_gen_financiador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_financiador (
    id integer NOT NULL,
    nombre character varying(1000),
    observaciones character varying(5000),
    fechacreacion date,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cor1440_gen_financiador_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_financiador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_financiador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_financiador_id_seq OWNED BY cor1440_gen_financiador.id;


--
-- Name: cor1440_gen_financiador_proyectofinanciero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_financiador_proyectofinanciero (
    financiador_id integer NOT NULL,
    proyectofinanciero_id integer NOT NULL
);


--
-- Name: cor1440_gen_informe; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_informe (
    id integer NOT NULL,
    titulo character varying(500) NOT NULL,
    filtrofechaini date NOT NULL,
    filtrofechafin date NOT NULL,
    filtroproyecto integer,
    filtroactividadarea integer,
    columnanombre boolean,
    columnatipo boolean,
    columnaobjetivo boolean,
    columnaproyecto boolean,
    columnapoblacion boolean,
    recomendaciones character varying(5000),
    avances character varying(5000),
    logros character varying(5000),
    dificultades character varying(5000),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    filtroproyectofinanciero integer,
    filtroresponsable integer,
    filtrooficina integer,
    columnafecha boolean,
    columnaresponsable boolean
);


--
-- Name: cor1440_gen_informe_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_informe_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_informe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_informe_id_seq OWNED BY cor1440_gen_informe.id;


--
-- Name: cor1440_gen_proyecto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_proyecto (
    id integer NOT NULL,
    nombre character varying(1000),
    observaciones character varying(5000),
    fechainicio date,
    fechacierre date,
    resultados character varying(5000),
    fechacreacion date,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cor1440_gen_proyecto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_proyecto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_proyecto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_proyecto_id_seq OWNED BY cor1440_gen_proyecto.id;


--
-- Name: cor1440_gen_proyecto_proyectofinanciero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_proyecto_proyectofinanciero (
    proyecto_id integer NOT NULL,
    proyectofinanciero_id integer NOT NULL
);


--
-- Name: cor1440_gen_proyectofinanciero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_proyectofinanciero (
    id integer NOT NULL,
    nombre character varying(1000),
    observaciones character varying(5000),
    fechainicio date,
    fechacierre date,
    responsable_id integer,
    fechacreacion date,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    compromisos character varying(5000),
    monto integer
);


--
-- Name: cor1440_gen_proyectofinanciero_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_proyectofinanciero_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_proyectofinanciero_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_proyectofinanciero_id_seq OWNED BY cor1440_gen_proyectofinanciero.id;


--
-- Name: cor1440_gen_rangoedadac; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cor1440_gen_rangoedadac (
    id integer NOT NULL,
    nombre character varying(255),
    limiteinferior integer,
    limitesuperior integer,
    fechacreacion date,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000)
);


--
-- Name: cor1440_gen_rangoedadac_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cor1440_gen_rangoedadac_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cor1440_gen_rangoedadac_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cor1440_gen_rangoedadac_id_seq OWNED BY cor1440_gen_rangoedadac.id;


--
-- Name: respuesta_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE respuesta_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_ayudasjr_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudasjr_respuesta (
    id_ayudasjr integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_respuesta integer NOT NULL
);


--
-- Name: sivel2_sjr_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_respuesta (
    id_caso integer NOT NULL,
    fechaatencion date NOT NULL,
    prorrogas boolean,
    numprorrogas integer,
    montoprorrogas integer,
    fechaultima date,
    lugarultima character varying(500),
    entregada boolean,
    proxprorroga boolean,
    turno character varying(100),
    lugar character varying(500),
    descamp character varying(5000),
    compromisos character varying(5000),
    remision character varying(5000),
    orientaciones character varying(5000),
    gestionessjr character varying(5000),
    observaciones character varying(5000),
    id_personadesea integer DEFAULT 0,
    verifcsjr character varying(5000),
    verifcper character varying(5000),
    efectividad character varying(5000),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('respuesta_seq'::regclass) NOT NULL,
    detallear character varying(5000),
    montoar integer,
    cantidadayes character varying(50),
    institucionayes character varying(500),
    informacionder boolean,
    accionesder character varying(5000),
    detallemotivo character varying(5000),
    difobsprog character varying(5000),
    detalleal character varying(5000),
    montoal integer,
    detalleap character varying(5000),
    montoap integer,
    detalleem character varying(5000),
    montoem integer
);


--
-- Name: cres1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW cres1 AS
 SELECT caso.id AS id_caso,
    respuesta.fechaatencion,
    casosjr.oficina_id,
    ayudasjr_respuesta.id_ayudasjr
   FROM sivel2_gen_caso caso,
    sivel2_sjr_casosjr casosjr,
    sivel2_sjr_respuesta respuesta,
    sivel2_sjr_ayudasjr_respuesta ayudasjr_respuesta
  WHERE ((caso.id = casosjr.id_caso) AND (caso.id = respuesta.id_caso) AND (respuesta.id = ayudasjr_respuesta.id_respuesta));


--
-- Name: educacionpropia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE educacionpropia (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: educacionpropia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE educacionpropia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: educacionpropia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE educacionpropia_id_seq OWNED BY educacionpropia.id;


--
-- Name: emprendimiento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emprendimiento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emprendimiento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emprendimiento (
    id integer DEFAULT nextval('emprendimiento_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT emprendimiento_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: emprendimiento_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE emprendimiento_respuesta (
    id_respuesta integer NOT NULL,
    id_emprendimiento integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: estadocaso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE estadocaso (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: estadocaso_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estadocaso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estadocaso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estadocaso_id_seq OWNED BY estadocaso.id;


--
-- Name: evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento (
    id integer NOT NULL,
    caso_id integer,
    diasemana integer,
    hora time without time zone,
    ubicacion_id integer,
    situacionriesgo character varying(1) DEFAULT 'I'::character varying,
    solicitomedidas character varying(1) DEFAULT 'I'::character varying,
    denuncia character varying(1) DEFAULT 'I'::character varying,
    testigo character varying(1) DEFAULT 'I'::character varying,
    afectacionotra character varying(500) DEFAULT 'I'::character varying,
    quisieradenunciar character varying(1) DEFAULT 'I'::character varying,
    recibidoreparacion character varying(1) DEFAULT 'I'::character varying,
    denunciaante character varying(1) DEFAULT 'I'::character varying,
    valoracionjusticia character varying(1) DEFAULT 'R'::character varying,
    resguardo character varying(500) DEFAULT ''::character varying,
    comunidad character varying(500) DEFAULT ''::character varying,
    medidasrecibidas character varying(5000) DEFAULT ''::character varying,
    brindadaproteccion character varying(5000) DEFAULT ''::character varying,
    descripcionafectacion character varying(5000) DEFAULT ''::character varying,
    relacionprespvic character varying(500) DEFAULT ''::character varying,
    numvecesantes character varying,
    actividadesdejadas character varying(5000) DEFAULT ''::character varying,
    reaccionfamiliaycomunidad character varying(5000) DEFAULT ''::character varying,
    avancescaso character varying(5000) DEFAULT ''::character varying,
    etapaproceso character varying(500) DEFAULT ''::character varying,
    compromisosadquiridos character varying(5000) DEFAULT ''::character varying,
    observaciones character varying(5000) DEFAULT ''::character varying,
    acompnecesita character varying(5000) DEFAULT ''::character varying,
    motivonodenuncia_id integer DEFAULT 0,
    dia integer,
    mes integer,
    anio integer,
    diadenuncia integer,
    mesdenuncia integer,
    aniodenuncia integer,
    departamento_id integer,
    municipio_id integer,
    relacionadocon character varying(1) DEFAULT 'S'::character varying,
    seguimientojudicial character varying(5000),
    seguimientopsicosocial character varying(5000),
    telcontacto character varying(128),
    quereparacion character varying(5120),
    fechaseguimiento date,
    sancionadovictimario character varying(1)
);


--
-- Name: evento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_id_seq OWNED BY evento.id;


--
-- Name: evento_motivonodenuncia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_motivonodenuncia (
    evento_id integer NOT NULL,
    motivonodenuncia_id integer NOT NULL
);


--
-- Name: evento_relacionprvic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_relacionprvic (
    evento_id integer NOT NULL,
    relacionprvic_id integer NOT NULL
);


--
-- Name: evento_tafectacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_tafectacion (
    evento_id integer NOT NULL,
    tafectacion_id integer NOT NULL
);


--
-- Name: evento_tapoyo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_tapoyo (
    evento_id integer NOT NULL,
    tapoyo_id integer NOT NULL
);


--
-- Name: eventopresponsable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE eventopresponsable (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    presponsable_id integer NOT NULL
);


--
-- Name: eventopresponsable_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE eventopresponsable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventopresponsable_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE eventopresponsable_id_seq OWNED BY eventopresponsable.id;


--
-- Name: fotra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fotra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heb412_gen_campohc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE heb412_gen_campohc (
    id integer NOT NULL,
    doc_id integer NOT NULL,
    nombrecampo character varying(127) NOT NULL,
    columna character varying(5) NOT NULL,
    fila integer
);


--
-- Name: heb412_gen_campohc_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE heb412_gen_campohc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heb412_gen_campohc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE heb412_gen_campohc_id_seq OWNED BY heb412_gen_campohc.id;


--
-- Name: heb412_gen_campoplantillahcm; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE heb412_gen_campoplantillahcm (
    id integer NOT NULL,
    plantillahcm_id integer,
    nombrecampo character varying(127),
    columna character varying(5)
);


--
-- Name: heb412_gen_campoplantillahcm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE heb412_gen_campoplantillahcm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heb412_gen_campoplantillahcm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE heb412_gen_campoplantillahcm_id_seq OWNED BY heb412_gen_campoplantillahcm.id;


--
-- Name: heb412_gen_doc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE heb412_gen_doc (
    id integer NOT NULL,
    nombre character varying(512),
    tipodoc character varying(1),
    dirpapa integer,
    url character varying(1024),
    fuente character varying(1024),
    descripcion character varying(5000),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    adjunto_file_name character varying,
    adjunto_content_type character varying,
    adjunto_file_size integer,
    adjunto_updated_at timestamp without time zone,
    nombremenu character varying(127),
    vista character varying(255),
    filainicial integer,
    ruta character varying(2047),
    licencia character varying(255),
    tdoc_id integer,
    tdoc_type character varying
);


--
-- Name: heb412_gen_doc_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE heb412_gen_doc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heb412_gen_doc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE heb412_gen_doc_id_seq OWNED BY heb412_gen_doc.id;


--
-- Name: heb412_gen_plantillahcm; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE heb412_gen_plantillahcm (
    id integer NOT NULL,
    ruta character varying(2047) NOT NULL,
    descripcion character varying(2047),
    fuente character varying(1023),
    licencia character varying(1023),
    vista character varying(127) NOT NULL,
    nombremenu character varying(127) NOT NULL,
    filainicial integer NOT NULL
);


--
-- Name: heb412_gen_plantillahcm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE heb412_gen_plantillahcm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: heb412_gen_plantillahcm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE heb412_gen_plantillahcm_id_seq OWNED BY heb412_gen_plantillahcm.id;


--
-- Name: idioma_victimasjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE idioma_victimasjr (
    sivel2_sjr_idioma_id integer NOT NULL,
    sivel2_sjr_victimasjr_id integer NOT NULL
);


--
-- Name: instanciader_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instanciader_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mecanismoder_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mecanismoder_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: motivoconsulta_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE motivoconsulta_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: motivonodenuncia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE motivonodenuncia (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: motivonodenuncia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE motivonodenuncia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: motivonodenuncia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE motivonodenuncia_id_seq OWNED BY motivonodenuncia.id;


--
-- Name: refugio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE refugio (
    id integer NOT NULL,
    id_caso integer,
    fechasalida date,
    id_salida integer,
    fechallegada date,
    id_llegada integer,
    id_causaref integer,
    observaciones character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: refugio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE refugio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refugio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE refugio_id_seq OWNED BY refugio.id;


--
-- Name: regimensalud_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regimensalud_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relacionprvic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE relacionprvic (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: relacionprvic_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE relacionprvic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relacionprvic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE relacionprvic_id_seq OWNED BY relacionprvic.id;


--
-- Name: religion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE religion (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: religion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE religion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: religion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE religion_id_seq OWNED BY religion.id;


--
-- Name: resagresion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE resagresion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sip_anexo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_anexo (
    id integer NOT NULL,
    descripcion character varying(1500) COLLATE public.es_co_utf_8,
    adjunto_file_name character varying(255),
    adjunto_content_type character varying(255),
    adjunto_file_size integer,
    adjunto_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sip_anexo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_anexo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_anexo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sip_anexo_id_seq OWNED BY sip_anexo.id;


--
-- Name: sip_etiqueta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_etiqueta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_etiqueta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_etiqueta (
    id integer DEFAULT nextval('sip_etiqueta_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT etiqueta_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_fuenteprensa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_fuenteprensa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_fuenteprensa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_fuenteprensa (
    id integer DEFAULT nextval('sip_fuenteprensa_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    tfuente character varying(25),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT sip_fuenteprensa_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_mundep_sinorden; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW sip_mundep_sinorden AS
 SELECT ((sip_departamento.id_deplocal * 1000) + sip_municipio.id_munlocal) AS idlocal,
    (((sip_municipio.nombre)::text || ' / '::text) || (sip_departamento.nombre)::text) AS nombre
   FROM (sip_municipio
     JOIN sip_departamento ON ((sip_municipio.id_departamento = sip_departamento.id)))
  WHERE ((sip_departamento.id_pais = 170) AND (sip_municipio.fechadeshabilitacion IS NULL) AND (sip_departamento.fechadeshabilitacion IS NULL))
UNION
 SELECT sip_departamento.id_deplocal AS idlocal,
    sip_departamento.nombre
   FROM sip_departamento
  WHERE ((sip_departamento.id_pais = 170) AND (sip_departamento.fechadeshabilitacion IS NULL));


--
-- Name: sip_mundep; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW sip_mundep AS
 SELECT sip_mundep_sinorden.idlocal,
    sip_mundep_sinorden.nombre,
    to_tsvector('spanish'::regconfig, unaccent(sip_mundep_sinorden.nombre)) AS mundep
   FROM sip_mundep_sinorden
  ORDER BY (sip_mundep_sinorden.nombre COLLATE es_co_utf_8)
  WITH NO DATA;


--
-- Name: sip_oficina_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_oficina_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_oficina; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_oficina (
    id integer DEFAULT nextval('sip_oficina_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT regionsjr_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_pais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_pais (
    id integer NOT NULL,
    nombre character varying(200) COLLATE public.es_co_utf_8 NOT NULL,
    nombreiso character varying(200) NOT NULL,
    latitud double precision,
    longitud double precision,
    alfa2 character varying(2),
    alfa3 character varying(3),
    codiso integer,
    div1 character varying(100),
    div2 character varying(100),
    div3 character varying(100),
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT pais_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_pais_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_pais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_pais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sip_pais_id_seq OWNED BY sip_pais.id;


--
-- Name: sip_persona_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_persona_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_persona (
    id integer DEFAULT nextval('sip_persona_id_seq'::regclass) NOT NULL,
    nombres character varying(100) COLLATE public.es_co_utf_8 NOT NULL,
    apellidos character varying(100) COLLATE public.es_co_utf_8 NOT NULL,
    anionac integer,
    mesnac integer,
    dianac integer,
    sexo character(1) NOT NULL,
    numerodocumento character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_pais integer,
    nacionalde integer,
    tdocumento_id integer,
    id_departamento integer,
    id_municipio integer,
    id_clase integer,
    CONSTRAINT persona_check CHECK (((dianac IS NULL) OR (((dianac >= 1) AND (((mesnac = 1) OR (mesnac = 3) OR (mesnac = 5) OR (mesnac = 7) OR (mesnac = 8) OR (mesnac = 10) OR (mesnac = 12)) AND (dianac <= 31))) OR (((mesnac = 4) OR (mesnac = 6) OR (mesnac = 9) OR (mesnac = 11)) AND (dianac <= 30)) OR ((mesnac = 2) AND (dianac <= 29))))),
    CONSTRAINT persona_mesnac_check CHECK (((mesnac IS NULL) OR ((mesnac >= 1) AND (mesnac <= 12)))),
    CONSTRAINT persona_sexo_check CHECK (((sexo = 'S'::bpchar) OR (sexo = 'F'::bpchar) OR (sexo = 'M'::bpchar)))
);


--
-- Name: sip_persona_trelacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_persona_trelacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_persona_trelacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_persona_trelacion (
    persona1 integer NOT NULL,
    persona2 integer NOT NULL,
    id_trelacion character(2) DEFAULT 'SI'::bpchar NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('sip_persona_trelacion_id_seq'::regclass) NOT NULL
);


--
-- Name: sip_tclase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_tclase (
    id character varying(10) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT tclase_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_tdocumento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_tdocumento (
    id integer NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    sigla character varying(100),
    formatoregex character varying(500),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8
);


--
-- Name: sip_tdocumento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_tdocumento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_tdocumento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sip_tdocumento_id_seq OWNED BY sip_tdocumento.id;


--
-- Name: sip_trelacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_trelacion (
    id character(2) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    inverso character varying(2),
    CONSTRAINT trelacion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sip_tsitio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sip_tsitio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sip_tsitio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sip_tsitio (
    id integer DEFAULT nextval('sip_tsitio_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000) COLLATE public.es_co_utf_8,
    CONSTRAINT tsitio_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_actividadoficio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_actividadoficio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_actividadoficio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_actividadoficio (
    id integer DEFAULT nextval('sivel2_gen_actividadoficio_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT actividadoficio_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_acto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_acto (
    id_presponsable integer NOT NULL,
    id_categoria integer NOT NULL,
    id_persona integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('acto_seq'::regclass) NOT NULL,
    evento_id integer
);


--
-- Name: sivel2_gen_actocolectivo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_actocolectivo (
    id_presponsable integer NOT NULL,
    id_categoria integer NOT NULL,
    id_grupoper integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_anexo_caso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_anexo_caso (
    id integer DEFAULT nextval('anexo_seq'::regclass) NOT NULL,
    id_caso integer NOT NULL,
    fecha date NOT NULL,
    fuenteprensa_id integer,
    fechaffrecuente date,
    id_fotra integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_anexo integer NOT NULL
);


--
-- Name: sivel2_gen_antecedente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_antecedente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_antecedente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_antecedente (
    id integer DEFAULT nextval('sivel2_gen_antecedente_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT antecedente_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_antecedente_caso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_antecedente_caso (
    id_antecedente integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_antecedente_combatiente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_antecedente_combatiente (
    id_antecedente integer,
    id_combatiente integer
);


--
-- Name: sivel2_gen_antecedente_victima; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_antecedente_victima (
    id_antecedente integer NOT NULL,
    id_persona integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_victima integer
);


--
-- Name: sivel2_gen_antecedente_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_antecedente_victimacolectiva (
    id_antecedente integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_caso_categoria_presponsable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_categoria_presponsable (
    id_tviolencia character varying(1) NOT NULL,
    id_supracategoria integer NOT NULL,
    id_categoria integer NOT NULL,
    id_caso integer NOT NULL,
    id_presponsable integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_caso_presponsable integer NOT NULL
);


--
-- Name: sivel2_gen_caso_contexto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_contexto (
    id_caso integer NOT NULL,
    id_contexto integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_caso_etiqueta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_etiqueta (
    id_caso integer NOT NULL,
    id_etiqueta integer NOT NULL,
    id_usuario integer NOT NULL,
    fecha date NOT NULL,
    observaciones character varying(5000),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('caso_etiqueta_seq'::regclass) NOT NULL
);


--
-- Name: sivel2_gen_caso_fotra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_caso_fotra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_caso_fotra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_fotra (
    id_caso integer NOT NULL,
    id_fotra integer,
    anotacion character varying(200),
    fecha date NOT NULL,
    ubicacionfisica character varying(100),
    tfuente character varying(25),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    id integer DEFAULT nextval('sivel2_gen_caso_fotra_seq'::regclass) NOT NULL,
    anexo_caso_id integer
);


--
-- Name: sivel2_gen_caso_frontera; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_frontera (
    id_frontera integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_caso_fuenteprensa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_caso_fuenteprensa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_caso_fuenteprensa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_fuenteprensa (
    fecha date NOT NULL,
    ubicacion character varying(100),
    clasificacion character varying(100),
    ubicacionfisica character varying(100),
    fuenteprensa_id integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('sivel2_gen_caso_fuenteprensa_seq'::regclass) NOT NULL,
    anexo_caso_id integer
);


--
-- Name: sivel2_gen_caso_presponsable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_presponsable (
    id_caso integer NOT NULL,
    id_presponsable integer NOT NULL,
    tipo integer DEFAULT 0 NOT NULL,
    bloque character varying(50),
    frente character varying(50),
    brigada character varying(50),
    batallon character varying(50),
    division character varying(50),
    otro character varying(500),
    id integer DEFAULT nextval('caso_presponsable_seq'::regclass) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_caso_region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_region (
    id_region integer NOT NULL,
    id_caso integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_caso_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_caso_usuario (
    id_usuario integer NOT NULL,
    id_caso integer NOT NULL,
    fechainicio date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_categoria (
    id integer NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    id_pconsolidado integer,
    contadaen integer,
    tipocat character(1) DEFAULT 'I'::bpchar,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    supracategoria_id integer,
    CONSTRAINT categoria_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion))),
    CONSTRAINT categoria_tipocat_check CHECK (((tipocat = 'I'::bpchar) OR (tipocat = 'C'::bpchar) OR (tipocat = 'O'::bpchar)))
);


--
-- Name: sivel2_gen_combatiente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_combatiente (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    alias character varying(500),
    edad integer,
    sexo character varying(1) DEFAULT 'S'::character varying NOT NULL,
    id_resagresion integer DEFAULT 1 NOT NULL,
    id_profesion integer DEFAULT 22,
    id_rangoedad integer DEFAULT 6,
    id_filiacion integer DEFAULT 10,
    id_sectorsocial integer DEFAULT 15,
    id_organizacion integer DEFAULT 16,
    id_vinculoestado integer DEFAULT 38,
    id_caso integer,
    organizacionarmada integer DEFAULT 35,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sivel2_gen_combatiente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_combatiente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_combatiente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sivel2_gen_combatiente_id_seq OWNED BY sivel2_gen_combatiente.id;


--
-- Name: sivel2_sjr_statusmigratorio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_statusmigratorio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_statusmigratorio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_statusmigratorio (
    id integer DEFAULT nextval('sivel2_sjr_statusmigratorio_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT statusmigratorio_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE usuario (
    id integer DEFAULT nextval('usuario_id_seq'::regclass) NOT NULL,
    nusuario character varying(15) NOT NULL,
    password character varying(64) DEFAULT ''::character varying NOT NULL,
    nombre character varying(50) COLLATE public.es_co_utf_8,
    descripcion character varying(50),
    rol integer DEFAULT 4,
    idioma character varying(6) DEFAULT 'es_CO'::character varying NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0 NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    oficina_id integer,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    CONSTRAINT usuario_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion))),
    CONSTRAINT usuario_rol_check CHECK ((rol >= 1))
);


--
-- Name: sivel2_gen_conscaso1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW sivel2_gen_conscaso1 AS
 SELECT casosjr.id_caso AS caso_id,
    array_to_string(ARRAY( SELECT (((persona.nombres)::text || ' '::text) || (persona.apellidos)::text)
           FROM sip_persona persona
          WHERE (persona.id = casosjr.contacto)), ', '::text) AS contacto,
    casosjr.fecharec,
    oficina.nombre AS oficina,
    usuario.nusuario,
    caso.fecha,
    statusmigratorio.nombre AS statusmigratorio,
    array_to_string(ARRAY( SELECT respuesta.fechaatencion
           FROM sivel2_sjr_respuesta respuesta
          WHERE (respuesta.id_caso = casosjr.id_caso)
          ORDER BY respuesta.fechaatencion DESC
         LIMIT 1), ', '::text) AS ultimafechaatencion,
    caso.memo,
    array_to_string(ARRAY( SELECT (((persona.nombres)::text || ' '::text) || (persona.apellidos)::text)
           FROM sip_persona persona,
            sivel2_gen_victima victima
          WHERE ((persona.id = victima.id_persona) AND (victima.id_caso = caso.id))), ', '::text) AS victimas
   FROM sivel2_sjr_casosjr casosjr,
    sivel2_gen_caso caso,
    sip_oficina oficina,
    usuario,
    sivel2_sjr_statusmigratorio statusmigratorio
  WHERE ((casosjr.id_caso = caso.id) AND (oficina.id = casosjr.oficina_id) AND (usuario.id = casosjr.asesor) AND (statusmigratorio.id = casosjr.id_statusmigratorio));


--
-- Name: sivel2_gen_conscaso; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW sivel2_gen_conscaso AS
 SELECT sivel2_gen_conscaso1.caso_id,
    sivel2_gen_conscaso1.contacto,
    sivel2_gen_conscaso1.fecharec,
    sivel2_gen_conscaso1.oficina,
    sivel2_gen_conscaso1.nusuario,
    sivel2_gen_conscaso1.fecha,
    sivel2_gen_conscaso1.statusmigratorio,
    sivel2_gen_conscaso1.ultimafechaatencion,
    sivel2_gen_conscaso1.memo,
    sivel2_gen_conscaso1.victimas,
    to_tsvector('spanish'::regconfig, unaccent(((((((((((((((((((sivel2_gen_conscaso1.caso_id || ' '::text) || sivel2_gen_conscaso1.contacto) || ' '::text) || replace(((sivel2_gen_conscaso1.fecharec)::character varying)::text, '-'::text, ' '::text)) || ' '::text) || (sivel2_gen_conscaso1.oficina)::text) || ' '::text) || (sivel2_gen_conscaso1.nusuario)::text) || ' '::text) || replace(((sivel2_gen_conscaso1.fecha)::character varying)::text, '-'::text, ' '::text)) || ' '::text) || (sivel2_gen_conscaso1.statusmigratorio)::text) || ' '::text) || replace(((sivel2_gen_conscaso1.ultimafechaatencion)::character varying)::text, '-'::text, ' '::text)) || ' '::text) || sivel2_gen_conscaso1.memo) || ' '::text) || sivel2_gen_conscaso1.victimas))) AS q
   FROM sivel2_gen_conscaso1
  WITH NO DATA;


--
-- Name: sivel2_gen_contexto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_contexto (
    id integer DEFAULT nextval('contexto_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT contexto_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_escolaridad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_escolaridad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_escolaridad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_escolaridad (
    id integer DEFAULT nextval('sivel2_gen_escolaridad_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT escolaridad_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_estadocivil_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_estadocivil_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_estadocivil; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_estadocivil (
    id integer DEFAULT nextval('sivel2_gen_estadocivil_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT estadocivil_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_etnia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_etnia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_etnia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_etnia (
    id integer DEFAULT nextval('sivel2_gen_etnia_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    descripcion character varying(1000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT etnia_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_filiacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_filiacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_filiacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_filiacion (
    id integer DEFAULT nextval('sivel2_gen_filiacion_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT filiacion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_filiacion_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_filiacion_victimacolectiva (
    id_filiacion integer DEFAULT 10 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_fotra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_fotra (
    id integer DEFAULT nextval('fotra_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_frontera_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_frontera_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_frontera; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_frontera (
    id integer DEFAULT nextval('sivel2_gen_frontera_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT frontera_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_grupoper_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_grupoper_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_grupoper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_grupoper (
    id integer DEFAULT nextval('sivel2_gen_grupoper_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    anotaciones character varying(1000),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_gen_iglesia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_iglesia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_iglesia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_iglesia (
    id integer DEFAULT nextval('sivel2_gen_iglesia_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    descripcion character varying(1000),
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT iglesia_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_intervalo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_intervalo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_intervalo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_intervalo (
    id integer DEFAULT nextval('sivel2_gen_intervalo_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    rango character varying(25) NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT intervalo_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_maternidad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_maternidad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_maternidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_maternidad (
    id integer DEFAULT nextval('sivel2_gen_maternidad_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT maternidad_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_organizacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_organizacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_organizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_organizacion (
    id integer DEFAULT nextval('sivel2_gen_organizacion_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT organizacion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_organizacion_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_organizacion_victimacolectiva (
    id_organizacion integer DEFAULT 16 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_pconsolidado_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_pconsolidado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_pconsolidado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_pconsolidado (
    id integer DEFAULT nextval('sivel2_gen_pconsolidado_id_seq'::regclass) NOT NULL,
    rotulo character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    tipoviolencia character varying(25) NOT NULL,
    clasificacion character varying(25) NOT NULL,
    peso integer DEFAULT 0,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT pconsolidado_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_presponsable_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_presponsable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_presponsable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_presponsable (
    id integer DEFAULT nextval('sivel2_gen_presponsable_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    papa integer,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT presponsable_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_profesion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_profesion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_profesion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_profesion (
    id integer DEFAULT nextval('sivel2_gen_profesion_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT profesion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_profesion_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_profesion_victimacolectiva (
    id_profesion integer DEFAULT 22 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_rangoedad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_rangoedad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_rangoedad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_rangoedad (
    id integer DEFAULT nextval('sivel2_gen_rangoedad_id_seq'::regclass) NOT NULL,
    nombre character varying(20) COLLATE public.es_co_utf_8 NOT NULL,
    rango character varying(20) NOT NULL,
    limiteinferior integer DEFAULT 0 NOT NULL,
    limitesuperior integer DEFAULT 0 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT rangoedad_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_rangoedad_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_rangoedad_victimacolectiva (
    id_rangoedad integer DEFAULT 6 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_region_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_region (
    id integer DEFAULT nextval('sivel2_gen_region_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT region_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_resagresion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_resagresion (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sivel2_gen_resagresion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_resagresion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_resagresion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sivel2_gen_resagresion_id_seq OWNED BY sivel2_gen_resagresion.id;


--
-- Name: sivel2_gen_sectorsocial_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_sectorsocial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_sectorsocial; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_sectorsocial (
    id integer DEFAULT nextval('sivel2_gen_sectorsocial_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT sectorsocial_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_sectorsocial_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_sectorsocial_victimacolectiva (
    id_sectorsocial integer DEFAULT 15 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_supracategoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_supracategoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_supracategoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_supracategoria (
    codigo integer,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    id_tviolencia character varying(1) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    id integer DEFAULT nextval('sivel2_gen_supracategoria_id_seq'::regclass) NOT NULL,
    CONSTRAINT supracategoria_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_tviolencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_tviolencia (
    id character(1) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    nomcorto character varying(10) NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT tviolencia_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_gen_victimacolectiva_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_victimacolectiva_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_victimacolectiva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_victimacolectiva (
    id_grupoper integer NOT NULL,
    id_caso integer NOT NULL,
    personasaprox integer,
    organizacionarmada integer DEFAULT 35,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer DEFAULT nextval('sivel2_gen_victimacolectiva_id_seq'::regclass) NOT NULL
);


--
-- Name: sivel2_gen_victimacolectiva_vinculoestado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_victimacolectiva_vinculoestado (
    id_vinculoestado integer DEFAULT 38 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victimacolectiva_id integer
);


--
-- Name: sivel2_gen_vinculoestado_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_gen_vinculoestado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_gen_vinculoestado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_gen_vinculoestado (
    id integer DEFAULT nextval('sivel2_gen_vinculoestado_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT vinculoestado_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_acreditacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_acreditacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_acreditacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_acreditacion (
    id integer DEFAULT nextval('sivel2_sjr_acreditacion_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT acreditacion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_actosjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_actosjr (
    fecha date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_acto integer NOT NULL,
    desplazamiento_id integer
);


--
-- Name: sivel2_sjr_actualizacionbase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_actualizacionbase (
    id character varying(10) NOT NULL,
    fecha date NOT NULL,
    descripcion character varying(500) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_aslegal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_aslegal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_aslegal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_aslegal (
    id integer DEFAULT nextval('sivel2_sjr_aslegal_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT aslegal_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_aslegal_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_aslegal_respuesta (
    id_respuesta integer NOT NULL,
    id_aslegal integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_ayudaestado_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_ayudaestado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_ayudaestado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudaestado (
    id integer DEFAULT nextval('sivel2_sjr_ayudaestado_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT ayudaestado_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_ayudaestado_derecho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudaestado_derecho (
    ayudaestado_id integer,
    derecho_id integer
);


--
-- Name: sivel2_sjr_ayudaestado_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudaestado_respuesta (
    id_respuesta integer NOT NULL,
    id_ayudaestado integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_ayudasjr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_ayudasjr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_ayudasjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudasjr (
    id integer DEFAULT nextval('sivel2_sjr_ayudasjr_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT ayudasjr_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_ayudasjr_derecho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_ayudasjr_derecho (
    ayudasjr_id integer,
    derecho_id integer
);


--
-- Name: sivel2_sjr_clasifdesp_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_clasifdesp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_clasifdesp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_clasifdesp (
    id integer DEFAULT nextval('sivel2_sjr_clasifdesp_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT clasifdesp_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_comosupo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_comosupo (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_comosupo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_comosupo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_comosupo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sivel2_sjr_comosupo_id_seq OWNED BY sivel2_sjr_comosupo.id;


--
-- Name: sivel2_sjr_declaroante_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_declaroante_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_declaroante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_declaroante (
    id integer DEFAULT nextval('sivel2_sjr_declaroante_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT declaroante_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_derecho_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_derecho_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_derecho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_derecho (
    id integer DEFAULT nextval('sivel2_sjr_derecho_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT '2013-06-12'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT derecho_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_derecho_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_derecho_respuesta (
    id_respuesta integer NOT NULL,
    id_derecho integer DEFAULT 9 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_etiqueta_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_etiqueta_usuario (
    id integer NOT NULL,
    etiqueta_id integer,
    usuario_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_etiqueta_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_etiqueta_usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_etiqueta_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sivel2_sjr_etiqueta_usuario_id_seq OWNED BY sivel2_sjr_etiqueta_usuario.id;


--
-- Name: sivel2_sjr_idioma_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_idioma_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_idioma; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_idioma (
    id integer DEFAULT nextval('sivel2_sjr_idioma_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT '2014-02-14'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT idioma_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_inclusion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_inclusion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_inclusion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_inclusion (
    id integer DEFAULT nextval('sivel2_sjr_inclusion_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT inclusion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_instanciader; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_instanciader (
    id integer DEFAULT nextval('instanciader_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-06-12'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT instanciader_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_mecanismoder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_mecanismoder (
    id integer DEFAULT nextval('mecanismoder_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-06-12'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT mecanismoder_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_modalidadtierra_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_modalidadtierra_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_modalidadtierra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_modalidadtierra (
    id integer DEFAULT nextval('sivel2_sjr_modalidadtierra_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT modalidadtierra_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_motivoconsulta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_motivoconsulta (
    id integer DEFAULT nextval('motivoconsulta_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-05-13'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT motivoconsulta_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_motivosjr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_motivosjr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_motivosjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_motivosjr (
    id integer DEFAULT nextval('sivel2_sjr_motivosjr_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT '2013-06-16'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT motivosjr_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_motivosjr_derecho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_motivosjr_derecho (
    motivosjr_id integer,
    derecho_id integer
);


--
-- Name: sivel2_sjr_motivosjr_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_motivosjr_respuesta (
    id_respuesta integer NOT NULL,
    id_motivosjr integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_personadesea_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_personadesea_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_personadesea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_personadesea (
    id integer DEFAULT nextval('sivel2_sjr_personadesea_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-06-17'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT personadesea_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_progestado_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_progestado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_progestado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_progestado (
    id integer DEFAULT nextval('sivel2_sjr_progestado_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-06-17'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT progestado_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_progestado_derecho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_progestado_derecho (
    progestado_id integer,
    derecho_id integer
);


--
-- Name: sivel2_sjr_progestado_respuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_progestado_respuesta (
    id_respuesta integer NOT NULL,
    id_progestado integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sivel2_sjr_proteccion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_proteccion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_proteccion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_proteccion (
    id integer DEFAULT nextval('sivel2_sjr_proteccion_id_seq'::regclass) NOT NULL,
    nombre character varying(100) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT proteccion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_regimensalud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_regimensalud (
    id integer DEFAULT nextval('regimensalud_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT '2013-05-13'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT regimensalud_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_resagresion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_resagresion (
    id integer DEFAULT nextval('resagresion_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT resagresion_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_rolfamilia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_rolfamilia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_rolfamilia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_rolfamilia (
    id integer DEFAULT nextval('sivel2_sjr_rolfamilia_id_seq'::regclass) NOT NULL,
    nombre character varying(50) NOT NULL,
    fechacreacion date DEFAULT ('now'::text)::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT rolfamilia_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_tipodesp_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sivel2_sjr_tipodesp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sivel2_sjr_tipodesp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_tipodesp (
    id integer DEFAULT nextval('sivel2_sjr_tipodesp_id_seq'::regclass) NOT NULL,
    nombre character varying(500) COLLATE public.es_co_utf_8 NOT NULL,
    fechacreacion date DEFAULT '2013-05-24'::date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    observaciones character varying(5000),
    CONSTRAINT tipodesp_check CHECK (((fechadeshabilitacion IS NULL) OR (fechadeshabilitacion >= fechacreacion)))
);


--
-- Name: sivel2_sjr_victimasjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sivel2_sjr_victimasjr (
    sindocumento boolean,
    id_estadocivil integer DEFAULT 0,
    id_rolfamilia integer DEFAULT 0 NOT NULL,
    cabezafamilia boolean,
    id_maternidad integer DEFAULT 0,
    discapacitado boolean,
    id_actividadoficio integer DEFAULT 0,
    id_escolaridad integer DEFAULT 0,
    asisteescuela boolean,
    tienesisben boolean,
    id_departamento integer,
    id_municipio integer,
    nivelsisben integer,
    id_regimensalud integer DEFAULT 0,
    eps character varying(1000),
    libretamilitar boolean,
    distrito integer,
    progadultomayor boolean,
    fechadesagregacion date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id_victima integer NOT NULL,
    id_pais integer,
    enfermedad character varying(5000),
    ndiscapacidad character varying(100),
    incluidoruv character varying(1) DEFAULT 'I'::character varying,
    cabezahogar character varying(1) DEFAULT 'I'::character varying,
    sistemasalud character varying(1) DEFAULT 'I'::character varying,
    vicconflicto character varying(1) DEFAULT 'A'::character varying,
    liderazgo character varying(1) DEFAULT 'I'::character varying,
    residencia character varying(5000) DEFAULT ''::character varying,
    areatierra integer,
    comotierra character varying(5000) DEFAULT ''::character varying,
    resguardonac character varying(500) DEFAULT ''::character varying,
    comunidadnac character varying(500) DEFAULT ''::character varying,
    organizacionfilial character varying(500) DEFAULT ''::character varying,
    religion_id integer DEFAULT 0,
    educacionpropia_id integer DEFAULT 0,
    departamentores_id integer,
    municipiores_id integer,
    resguardores character varying(500),
    comunidadres character varying(500),
    comoingresos character varying(5000),
    tipoliderazgo character varying(5000)
);


--
-- Name: tafectacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tafectacion (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tafectacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tafectacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tafectacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tafectacion_id_seq OWNED BY tafectacion.id;


--
-- Name: tapoyo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tapoyo (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(5000),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tapoyo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tapoyo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tapoyo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tapoyo_id_seq OWNED BY tapoyo.id;


--
-- Name: tienetierra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tienetierra (
    id integer NOT NULL,
    nombre character varying(500) NOT NULL,
    observaciones character varying(500),
    fechacreacion date NOT NULL,
    fechadeshabilitacion date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tienetierra_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tienetierra_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tienetierra_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tienetierra_id_seq OWNED BY tienetierra.id;


--
-- Name: tienetierra_victimasjr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tienetierra_victimasjr (
    tienetierra_id integer NOT NULL,
    sivel2_sjr_victimasjr_id integer NOT NULL
);


--
-- Name: vvictimasoundexesp; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW vvictimasoundexesp AS
 SELECT sivel2_gen_victima.id_caso,
    sip_persona.id AS id_persona,
    (((sip_persona.nombres)::text || ' '::text) || (sip_persona.apellidos)::text) AS nomap,
    ( SELECT array_to_string(array_agg(soundexesp(n.s)), ' '::text) AS array_to_string
           FROM ( SELECT unnest(string_to_array(regexp_replace((((sip_persona.nombres)::text || ' '::text) || (sip_persona.apellidos)::text), '  *'::text, ' '::text), ' '::text)) AS s
                  ORDER BY (unnest(string_to_array(regexp_replace((((sip_persona.nombres)::text || ' '::text) || (sip_persona.apellidos)::text), '  *'::text, ' '::text), ' '::text)))) n) AS nomsoundexesp
   FROM sip_persona,
    sivel2_gen_victima
  WHERE (sip_persona.id = sivel2_gen_victima.id_persona)
  WITH NO DATA;


--
-- Name: acompanamiento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento ALTER COLUMN id SET DEFAULT nextval('acompanamiento_id_seq'::regclass);


--
-- Name: actoevento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY actoevento ALTER COLUMN id SET DEFAULT nextval('actoevento_id_seq'::regclass);


--
-- Name: consecuenciafamiliar id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciafamiliar ALTER COLUMN id SET DEFAULT nextval('consecuenciafamiliar_id_seq'::regclass);


--
-- Name: consecuenciafisica id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciafisica ALTER COLUMN id SET DEFAULT nextval('consecuenciafisica_id_seq'::regclass);


--
-- Name: consecuenciaindividual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciaindividual ALTER COLUMN id SET DEFAULT nextval('consecuenciaindividual_id_seq'::regclass);


--
-- Name: cor1440_gen_actividad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividad_id_seq'::regclass);


--
-- Name: cor1440_gen_actividad_proyecto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyecto ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividad_proyecto_id_seq'::regclass);


--
-- Name: cor1440_gen_actividad_rangoedadac id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_rangoedadac ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividad_rangoedadac_id_seq'::regclass);


--
-- Name: cor1440_gen_actividadarea id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadarea ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividadarea_id_seq'::regclass);


--
-- Name: cor1440_gen_actividadareas_actividad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadareas_actividad ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividadareas_actividad_id_seq'::regclass);


--
-- Name: cor1440_gen_actividadtipo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadtipo ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_actividadtipo_id_seq'::regclass);


--
-- Name: cor1440_gen_financiador id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_financiador ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_financiador_id_seq'::regclass);


--
-- Name: cor1440_gen_informe id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_informe_id_seq'::regclass);


--
-- Name: cor1440_gen_proyecto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_proyecto ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_proyecto_id_seq'::regclass);


--
-- Name: cor1440_gen_proyectofinanciero id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_proyectofinanciero ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_proyectofinanciero_id_seq'::regclass);


--
-- Name: cor1440_gen_rangoedadac id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_rangoedadac ALTER COLUMN id SET DEFAULT nextval('cor1440_gen_rangoedadac_id_seq'::regclass);


--
-- Name: educacionpropia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY educacionpropia ALTER COLUMN id SET DEFAULT nextval('educacionpropia_id_seq'::regclass);


--
-- Name: estadocaso id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estadocaso ALTER COLUMN id SET DEFAULT nextval('estadocaso_id_seq'::regclass);


--
-- Name: evento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento ALTER COLUMN id SET DEFAULT nextval('evento_id_seq'::regclass);


--
-- Name: eventopresponsable id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY eventopresponsable ALTER COLUMN id SET DEFAULT nextval('eventopresponsable_id_seq'::regclass);


--
-- Name: heb412_gen_campohc id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campohc ALTER COLUMN id SET DEFAULT nextval('heb412_gen_campohc_id_seq'::regclass);


--
-- Name: heb412_gen_campoplantillahcm id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campoplantillahcm ALTER COLUMN id SET DEFAULT nextval('heb412_gen_campoplantillahcm_id_seq'::regclass);


--
-- Name: heb412_gen_doc id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_doc ALTER COLUMN id SET DEFAULT nextval('heb412_gen_doc_id_seq'::regclass);


--
-- Name: heb412_gen_plantillahcm id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_plantillahcm ALTER COLUMN id SET DEFAULT nextval('heb412_gen_plantillahcm_id_seq'::regclass);


--
-- Name: motivonodenuncia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY motivonodenuncia ALTER COLUMN id SET DEFAULT nextval('motivonodenuncia_id_seq'::regclass);


--
-- Name: refugio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY refugio ALTER COLUMN id SET DEFAULT nextval('refugio_id_seq'::regclass);


--
-- Name: relacionprvic id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY relacionprvic ALTER COLUMN id SET DEFAULT nextval('relacionprvic_id_seq'::regclass);


--
-- Name: religion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY religion ALTER COLUMN id SET DEFAULT nextval('religion_id_seq'::regclass);


--
-- Name: sip_anexo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_anexo ALTER COLUMN id SET DEFAULT nextval('sip_anexo_id_seq'::regclass);


--
-- Name: sip_pais id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_pais ALTER COLUMN id SET DEFAULT nextval('sip_pais_id_seq'::regclass);


--
-- Name: sip_tdocumento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_tdocumento ALTER COLUMN id SET DEFAULT nextval('sip_tdocumento_id_seq'::regclass);


--
-- Name: sivel2_gen_combatiente id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente ALTER COLUMN id SET DEFAULT nextval('sivel2_gen_combatiente_id_seq'::regclass);


--
-- Name: sivel2_gen_resagresion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_resagresion ALTER COLUMN id SET DEFAULT nextval('sivel2_gen_resagresion_id_seq'::regclass);


--
-- Name: sivel2_sjr_comosupo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_comosupo ALTER COLUMN id SET DEFAULT nextval('sivel2_sjr_comosupo_id_seq'::regclass);


--
-- Name: sivel2_sjr_etiqueta_usuario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_etiqueta_usuario ALTER COLUMN id SET DEFAULT nextval('sivel2_sjr_etiqueta_usuario_id_seq'::regclass);


--
-- Name: tafectacion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tafectacion ALTER COLUMN id SET DEFAULT nextval('tafectacion_id_seq'::regclass);


--
-- Name: tapoyo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tapoyo ALTER COLUMN id SET DEFAULT nextval('tapoyo_id_seq'::regclass);


--
-- Name: tienetierra id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tienetierra ALTER COLUMN id SET DEFAULT nextval('tienetierra_id_seq'::regclass);


--
-- Name: acompanamiento acompanamiento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento
    ADD CONSTRAINT acompanamiento_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_actividadoficio actividadoficio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actividadoficio
    ADD CONSTRAINT actividadoficio_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_acto acto_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_key UNIQUE (id);


--
-- Name: sivel2_gen_acto acto_id_presponsable_id_categoria_id_persona_id_caso_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_presponsable_id_categoria_id_persona_id_caso_key UNIQUE (id_presponsable, id_categoria, id_persona, id_caso);


--
-- Name: sivel2_gen_acto acto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_actocolectivo actocolectivo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actocolectivo
    ADD CONSTRAINT actocolectivo_pkey PRIMARY KEY (id_presponsable, id_categoria, id_grupoper, id_caso);


--
-- Name: actoevento actoevento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY actoevento
    ADD CONSTRAINT actoevento_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_actosjr actosjr_id_acto_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_actosjr
    ADD CONSTRAINT actosjr_id_acto_key UNIQUE (id_acto);


--
-- Name: sivel2_sjr_actosjr actosjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_actosjr
    ADD CONSTRAINT actosjr_pkey PRIMARY KEY (id_acto);


--
-- Name: sivel2_sjr_actualizacionbase actualizacionbase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_actualizacionbase
    ADD CONSTRAINT actualizacionbase_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_anexo_caso anexo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_anexo_caso
    ADD CONSTRAINT anexo_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_antecedente_caso antecedente_caso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_caso
    ADD CONSTRAINT antecedente_caso_pkey PRIMARY KEY (id_antecedente, id_caso);


--
-- Name: sivel2_gen_antecedente antecedente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente
    ADD CONSTRAINT antecedente_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_antecedente_victima antecedente_victima_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT antecedente_victima_pkey PRIMARY KEY (id_antecedente, id_persona, id_caso);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: sivel2_sjr_aslegal aslegal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_aslegal
    ADD CONSTRAINT aslegal_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_aslegal_respuesta aslegal_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_aslegal_respuesta
    ADD CONSTRAINT aslegal_respuesta_pkey PRIMARY KEY (id_respuesta, id_aslegal);


--
-- Name: aspsicosocial aspsicosocial_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aspsicosocial
    ADD CONSTRAINT aspsicosocial_pkey PRIMARY KEY (id);


--
-- Name: aspsicosocial_respuesta aspsicosocial_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aspsicosocial_respuesta
    ADD CONSTRAINT aspsicosocial_respuesta_pkey PRIMARY KEY (id_respuesta, id_aspsicosocial);


--
-- Name: sivel2_sjr_ayudaestado ayudaestado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado
    ADD CONSTRAINT ayudaestado_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_ayudaestado_respuesta ayudaestado_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado_respuesta
    ADD CONSTRAINT ayudaestado_respuesta_pkey PRIMARY KEY (id_respuesta, id_ayudaestado);


--
-- Name: sivel2_sjr_ayudasjr ayudasjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr
    ADD CONSTRAINT ayudasjr_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_ayudasjr_respuesta ayudasjr_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr_respuesta
    ADD CONSTRAINT ayudasjr_respuesta_pkey PRIMARY KEY (id_respuesta, id_ayudasjr);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_pkey PRIMARY KEY (id_tviolencia, id_supracategoria, id_categoria, id_caso_presponsable);


--
-- Name: sivel2_gen_caso_contexto caso_contexto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_contexto
    ADD CONSTRAINT caso_contexto_pkey PRIMARY KEY (id_caso, id_contexto);


--
-- Name: sivel2_gen_caso_etiqueta caso_etiqueta_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_etiqueta
    ADD CONSTRAINT caso_etiqueta_id_key UNIQUE (id);


--
-- Name: sivel2_gen_caso_etiqueta caso_etiqueta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_etiqueta
    ADD CONSTRAINT caso_etiqueta_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_caso_frontera caso_frontera_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_frontera
    ADD CONSTRAINT caso_frontera_pkey PRIMARY KEY (id_frontera, id_caso);


--
-- Name: sivel2_gen_caso caso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso
    ADD CONSTRAINT caso_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_caso_presponsable caso_presponsable_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_presponsable
    ADD CONSTRAINT caso_presponsable_id_key UNIQUE (id);


--
-- Name: sivel2_gen_caso_presponsable caso_presponsable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_presponsable
    ADD CONSTRAINT caso_presponsable_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_caso_region caso_region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_region
    ADD CONSTRAINT caso_region_pkey PRIMARY KEY (id_region, id_caso);


--
-- Name: sivel2_gen_caso_usuario caso_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_usuario
    ADD CONSTRAINT caso_usuario_pkey PRIMARY KEY (id_usuario, id_caso);


--
-- Name: sivel2_sjr_casosjr casosjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_pkey PRIMARY KEY (id_caso);


--
-- Name: sivel2_gen_categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_clasifdesp clasifdesp_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_clasifdesp
    ADD CONSTRAINT clasifdesp_pkey PRIMARY KEY (id);


--
-- Name: consecuenciafamiliar consecuenciafamiliar_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciafamiliar
    ADD CONSTRAINT consecuenciafamiliar_pkey PRIMARY KEY (id);


--
-- Name: consecuenciafisica consecuenciafisica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciafisica
    ADD CONSTRAINT consecuenciafisica_pkey PRIMARY KEY (id);


--
-- Name: consecuenciaindividual consecuenciaindividual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consecuenciaindividual
    ADD CONSTRAINT consecuenciaindividual_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_contexto contexto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_contexto
    ADD CONSTRAINT contexto_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividad_proyecto cor1440_gen_actividad_proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyecto
    ADD CONSTRAINT cor1440_gen_actividad_proyecto_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividad_sip_anexo cor1440_gen_actividad_sip_anexo_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_sip_anexo
    ADD CONSTRAINT cor1440_gen_actividad_sip_anexo_id_key UNIQUE (id);


--
-- Name: cor1440_gen_actividad_sip_anexo cor1440_gen_actividad_sip_anexo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_sip_anexo
    ADD CONSTRAINT cor1440_gen_actividad_sip_anexo_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividadtipo cor1440_gen_actividadtipo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadtipo
    ADD CONSTRAINT cor1440_gen_actividadtipo_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_financiador cor1440_gen_financiador_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_financiador
    ADD CONSTRAINT cor1440_gen_financiador_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_informe cor1440_gen_informe_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT cor1440_gen_informe_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_proyecto cor1440_gen_proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_proyecto
    ADD CONSTRAINT cor1440_gen_proyecto_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_proyectofinanciero cor1440_gen_proyectofinanciero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_proyectofinanciero
    ADD CONSTRAINT cor1440_gen_proyectofinanciero_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_declaroante declaroante_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_declaroante
    ADD CONSTRAINT declaroante_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_derecho derecho_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_derecho
    ADD CONSTRAINT derecho_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_derecho_respuesta derecho_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_derecho_respuesta
    ADD CONSTRAINT derecho_respuesta_pkey PRIMARY KEY (id_respuesta, id_derecho);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_id_caso_fechaexpulsion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_id_caso_fechaexpulsion_key UNIQUE (id_caso, fechaexpulsion);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_id_key UNIQUE (id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_pkey PRIMARY KEY (id);


--
-- Name: educacionpropia educacionpropia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY educacionpropia
    ADD CONSTRAINT educacionpropia_pkey PRIMARY KEY (id);


--
-- Name: emprendimiento emprendimiento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emprendimiento
    ADD CONSTRAINT emprendimiento_pkey PRIMARY KEY (id);


--
-- Name: emprendimiento_respuesta emprendimiento_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emprendimiento_respuesta
    ADD CONSTRAINT emprendimiento_respuesta_pkey PRIMARY KEY (id_respuesta, id_emprendimiento);


--
-- Name: sivel2_gen_escolaridad escolaridad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_escolaridad
    ADD CONSTRAINT escolaridad_pkey PRIMARY KEY (id);


--
-- Name: estadocaso estadocaso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY estadocaso
    ADD CONSTRAINT estadocaso_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_estadocivil estadocivil_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_estadocivil
    ADD CONSTRAINT estadocivil_pkey PRIMARY KEY (id);


--
-- Name: sip_etiqueta etiqueta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_etiqueta
    ADD CONSTRAINT etiqueta_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_etnia etnia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_etnia
    ADD CONSTRAINT etnia_pkey PRIMARY KEY (id);


--
-- Name: evento evento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_pkey PRIMARY KEY (id);


--
-- Name: eventopresponsable eventopresponsable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eventopresponsable
    ADD CONSTRAINT eventopresponsable_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_filiacion filiacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_filiacion
    ADD CONSTRAINT filiacion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_fotra fotra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_fotra
    ADD CONSTRAINT fotra_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_frontera frontera_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_frontera
    ADD CONSTRAINT frontera_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_grupoper grupoper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_grupoper
    ADD CONSTRAINT grupoper_pkey PRIMARY KEY (id);


--
-- Name: heb412_gen_campohc heb412_gen_campohc_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campohc
    ADD CONSTRAINT heb412_gen_campohc_pkey PRIMARY KEY (id);


--
-- Name: heb412_gen_campoplantillahcm heb412_gen_campoplantillahcm_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campoplantillahcm
    ADD CONSTRAINT heb412_gen_campoplantillahcm_pkey PRIMARY KEY (id);


--
-- Name: heb412_gen_doc heb412_gen_doc_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_doc
    ADD CONSTRAINT heb412_gen_doc_pkey PRIMARY KEY (id);


--
-- Name: heb412_gen_plantillahcm heb412_gen_plantillahcm_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_plantillahcm
    ADD CONSTRAINT heb412_gen_plantillahcm_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_idioma idioma_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_idioma
    ADD CONSTRAINT idioma_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_iglesia iglesia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_iglesia
    ADD CONSTRAINT iglesia_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_inclusion inclusion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_inclusion
    ADD CONSTRAINT inclusion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_instanciader instanciader_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_instanciader
    ADD CONSTRAINT instanciader_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_intervalo intervalo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_intervalo
    ADD CONSTRAINT intervalo_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_maternidad maternidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_maternidad
    ADD CONSTRAINT maternidad_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_mecanismoder mecanismoder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_mecanismoder
    ADD CONSTRAINT mecanismoder_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_modalidadtierra modalidadtierra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_modalidadtierra
    ADD CONSTRAINT modalidadtierra_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_motivoconsulta motivoconsulta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivoconsulta
    ADD CONSTRAINT motivoconsulta_pkey PRIMARY KEY (id);


--
-- Name: motivonodenuncia motivonodenuncia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY motivonodenuncia
    ADD CONSTRAINT motivonodenuncia_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_motivosjr motivosjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr
    ADD CONSTRAINT motivosjr_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_motivosjr_respuesta motivosjr_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr_respuesta
    ADD CONSTRAINT motivosjr_respuesta_pkey PRIMARY KEY (id_respuesta, id_motivosjr);


--
-- Name: sivel2_gen_organizacion organizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_organizacion
    ADD CONSTRAINT organizacion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_pconsolidado pconsolidado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_pconsolidado
    ADD CONSTRAINT pconsolidado_pkey PRIMARY KEY (id);


--
-- Name: sip_persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_personadesea personadesea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_personadesea
    ADD CONSTRAINT personadesea_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_presponsable presponsable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_presponsable
    ADD CONSTRAINT presponsable_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_profesion profesion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_profesion
    ADD CONSTRAINT profesion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_progestado progestado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado
    ADD CONSTRAINT progestado_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_progestado_respuesta progestado_respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado_respuesta
    ADD CONSTRAINT progestado_respuesta_pkey PRIMARY KEY (id_respuesta, id_progestado);


--
-- Name: sivel2_sjr_proteccion proteccion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_proteccion
    ADD CONSTRAINT proteccion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_rangoedad rangoedad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_rangoedad
    ADD CONSTRAINT rangoedad_pkey PRIMARY KEY (id);


--
-- Name: refugio refugio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY refugio
    ADD CONSTRAINT refugio_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_regimensalud regimensalud_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_regimensalud
    ADD CONSTRAINT regimensalud_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_region region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);


--
-- Name: sip_oficina regionsjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_oficina
    ADD CONSTRAINT regionsjr_pkey PRIMARY KEY (id);


--
-- Name: relacionprvic relacionprvic_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relacionprvic
    ADD CONSTRAINT relacionprvic_pkey PRIMARY KEY (id);


--
-- Name: religion religion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY religion
    ADD CONSTRAINT religion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_resagresion resagresion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_resagresion
    ADD CONSTRAINT resagresion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_respuesta respuesta_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_respuesta
    ADD CONSTRAINT respuesta_id_key UNIQUE (id);


--
-- Name: sivel2_sjr_respuesta respuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_respuesta
    ADD CONSTRAINT respuesta_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_rolfamilia rolfamilia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_rolfamilia
    ADD CONSTRAINT rolfamilia_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_sectorsocial sectorsocial_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_sectorsocial
    ADD CONSTRAINT sectorsocial_pkey PRIMARY KEY (id);


--
-- Name: sip_clase sip_clase_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_clase
    ADD CONSTRAINT sip_clase_id_key UNIQUE (id);


--
-- Name: sip_clase sip_clase_id_municipio_id_clalocal_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_clase
    ADD CONSTRAINT sip_clase_id_municipio_id_clalocal_key UNIQUE (id_municipio, id_clalocal);


--
-- Name: sip_clase sip_clase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_clase
    ADD CONSTRAINT sip_clase_pkey PRIMARY KEY (id);


--
-- Name: sip_departamento sip_departamento_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_departamento
    ADD CONSTRAINT sip_departamento_id_key UNIQUE (id);


--
-- Name: sip_departamento sip_departamento_id_pais_id_deplocal_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_departamento
    ADD CONSTRAINT sip_departamento_id_pais_id_deplocal_key UNIQUE (id_pais, id_deplocal);


--
-- Name: sip_departamento sip_departamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_departamento
    ADD CONSTRAINT sip_departamento_pkey PRIMARY KEY (id);


--
-- Name: sip_fuenteprensa sip_fuenteprensa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_fuenteprensa
    ADD CONSTRAINT sip_fuenteprensa_pkey PRIMARY KEY (id);


--
-- Name: sip_municipio sip_municipio_id_departamento_id_munlocal_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_municipio
    ADD CONSTRAINT sip_municipio_id_departamento_id_munlocal_key UNIQUE (id_departamento, id_munlocal);


--
-- Name: sip_municipio sip_municipio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_municipio
    ADD CONSTRAINT sip_municipio_id_key UNIQUE (id);


--
-- Name: sip_municipio sip_municipio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_municipio
    ADD CONSTRAINT sip_municipio_pkey PRIMARY KEY (id);


--
-- Name: sip_persona_trelacion sip_persona_trelacion_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT sip_persona_trelacion_id_key UNIQUE (id);


--
-- Name: sip_persona_trelacion sip_persona_trelacion_persona1_persona2_id_trelacion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT sip_persona_trelacion_persona1_persona2_id_trelacion_key UNIQUE (persona1, persona2, id_trelacion);


--
-- Name: sip_persona_trelacion sip_persona_trelacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT sip_persona_trelacion_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividad sivel2_gen_actividad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad
    ADD CONSTRAINT sivel2_gen_actividad_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividad_rangoedadac sivel2_gen_actividad_rangoedadac_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_rangoedadac
    ADD CONSTRAINT sivel2_gen_actividad_rangoedadac_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividadarea sivel2_gen_actividadarea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadarea
    ADD CONSTRAINT sivel2_gen_actividadarea_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_actividadareas_actividad sivel2_gen_actividadareas_actividad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividadareas_actividad
    ADD CONSTRAINT sivel2_gen_actividadareas_actividad_pkey PRIMARY KEY (id);


--
-- Name: sip_anexo sivel2_gen_anexoactividad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_anexo
    ADD CONSTRAINT sivel2_gen_anexoactividad_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_caso_fotra sivel2_gen_caso_fotra_id_caso_nombre_fecha_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fotra
    ADD CONSTRAINT sivel2_gen_caso_fotra_id_caso_nombre_fecha_key UNIQUE (id_caso, nombre, fecha);


--
-- Name: sivel2_gen_caso_fotra sivel2_gen_caso_fotra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fotra
    ADD CONSTRAINT sivel2_gen_caso_fotra_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_caso_fuenteprensa sivel2_gen_caso_fuenteprensa_id_caso_fecha_fuenteprensa_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fuenteprensa
    ADD CONSTRAINT sivel2_gen_caso_fuenteprensa_id_caso_fecha_fuenteprensa_id_key UNIQUE (id_caso, fecha, fuenteprensa_id);


--
-- Name: sivel2_gen_caso_fuenteprensa sivel2_gen_caso_fuenteprensa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fuenteprensa
    ADD CONSTRAINT sivel2_gen_caso_fuenteprensa_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_combatiente sivel2_gen_combatiente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT sivel2_gen_combatiente_pkey PRIMARY KEY (id);


--
-- Name: sip_pais sivel2_gen_pais_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_pais
    ADD CONSTRAINT sivel2_gen_pais_pkey PRIMARY KEY (id);


--
-- Name: cor1440_gen_rangoedadac sivel2_gen_rangoedadac_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_rangoedadac
    ADD CONSTRAINT sivel2_gen_rangoedadac_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_resagresion sivel2_gen_resagresion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_resagresion
    ADD CONSTRAINT sivel2_gen_resagresion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_supracategoria sivel2_gen_supracategoria_id_tviolencia_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_supracategoria
    ADD CONSTRAINT sivel2_gen_supracategoria_id_tviolencia_codigo_key UNIQUE (id_tviolencia, codigo);


--
-- Name: sivel2_gen_supracategoria sivel2_gen_supracategoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_supracategoria
    ADD CONSTRAINT sivel2_gen_supracategoria_pkey PRIMARY KEY (id);


--
-- Name: sip_tdocumento sivel2_gen_tdocumento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_tdocumento
    ADD CONSTRAINT sivel2_gen_tdocumento_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_victimacolectiva sivel2_gen_victimacolectiva_id_caso_id_grupoper_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT sivel2_gen_victimacolectiva_id_caso_id_grupoper_key UNIQUE (id_caso, id_grupoper);


--
-- Name: sivel2_gen_victimacolectiva sivel2_gen_victimacolectiva_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT sivel2_gen_victimacolectiva_id_key UNIQUE (id);


--
-- Name: sivel2_gen_victimacolectiva sivel2_gen_victimacolectiva_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT sivel2_gen_victimacolectiva_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_acreditacion sivel2_sjr_acreditacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_acreditacion
    ADD CONSTRAINT sivel2_sjr_acreditacion_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_comosupo sivel2_sjr_comosupo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_comosupo
    ADD CONSTRAINT sivel2_sjr_comosupo_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_etiqueta_usuario sivel2_sjr_etiqueta_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_etiqueta_usuario
    ADD CONSTRAINT sivel2_sjr_etiqueta_usuario_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_statusmigratorio statusmigratorio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_statusmigratorio
    ADD CONSTRAINT statusmigratorio_pkey PRIMARY KEY (id);


--
-- Name: tafectacion tafectacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tafectacion
    ADD CONSTRAINT tafectacion_pkey PRIMARY KEY (id);


--
-- Name: tapoyo tapoyo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tapoyo
    ADD CONSTRAINT tapoyo_pkey PRIMARY KEY (id);


--
-- Name: sip_tclase tclase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_tclase
    ADD CONSTRAINT tclase_pkey PRIMARY KEY (id);


--
-- Name: tienetierra tienetierra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tienetierra
    ADD CONSTRAINT tienetierra_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_tipodesp tipodesp_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_tipodesp
    ADD CONSTRAINT tipodesp_pkey PRIMARY KEY (id);


--
-- Name: sip_trelacion trelacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_trelacion
    ADD CONSTRAINT trelacion_pkey PRIMARY KEY (id);


--
-- Name: sip_tsitio tsitio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_tsitio
    ADD CONSTRAINT tsitio_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_tviolencia tviolencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_tviolencia
    ADD CONSTRAINT tviolencia_pkey PRIMARY KEY (id);


--
-- Name: sip_ubicacion ubicacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT ubicacion_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_nusuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_nusuario_key UNIQUE (nusuario);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: sivel2_gen_victima victima_id_caso_id_persona_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_id_persona_key UNIQUE (id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_caso_id_persona_key1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_id_persona_key1 UNIQUE (id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_caso_id_persona_key2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_id_persona_key2 UNIQUE (id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_caso_id_persona_key3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_id_persona_key3 UNIQUE (id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_caso_id_persona_key4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_id_persona_key4 UNIQUE (id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_key UNIQUE (id);


--
-- Name: sivel2_gen_victima victima_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_pkey PRIMARY KEY (id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_pkey PRIMARY KEY (id_victima);


--
-- Name: sivel2_gen_vinculoestado vinculoestado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_vinculoestado
    ADD CONSTRAINT vinculoestado_pkey PRIMARY KEY (id);


--
-- Name: busca_conscaso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX busca_conscaso ON sivel2_gen_conscaso USING gin (q);


--
-- Name: index_cor1440_gen_actividad_on_usuario_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cor1440_gen_actividad_on_usuario_id ON cor1440_gen_actividad USING btree (usuario_id);


--
-- Name: index_cor1440_gen_actividad_sip_anexo_on_anexo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cor1440_gen_actividad_sip_anexo_on_anexo_id ON cor1440_gen_actividad_sip_anexo USING btree (anexo_id);


--
-- Name: index_heb412_gen_doc_on_tdoc_type_and_tdoc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_heb412_gen_doc_on_tdoc_type_and_tdoc_id ON heb412_gen_doc USING btree (tdoc_type, tdoc_id);


--
-- Name: index_sivel2_gen_actividad_on_rangoedadac_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_gen_actividad_on_rangoedadac_id ON cor1440_gen_actividad USING btree (rangoedadac_id);


--
-- Name: index_sivel2_gen_actividad_rangoedadac_on_actividad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_gen_actividad_rangoedadac_on_actividad_id ON cor1440_gen_actividad_rangoedadac USING btree (actividad_id);


--
-- Name: index_sivel2_gen_actividad_rangoedadac_on_rangoedadac_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_gen_actividad_rangoedadac_on_rangoedadac_id ON cor1440_gen_actividad_rangoedadac USING btree (rangoedadac_id);


--
-- Name: index_sivel2_gen_antecedente_combatiente_on_id_antecedente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_gen_antecedente_combatiente_on_id_antecedente ON sivel2_gen_antecedente_combatiente USING btree (id_antecedente);


--
-- Name: index_sivel2_gen_antecedente_combatiente_on_id_combatiente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_gen_antecedente_combatiente_on_id_combatiente ON sivel2_gen_antecedente_combatiente USING btree (id_combatiente);


--
-- Name: index_sivel2_sjr_casosjr_on_comosupo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sivel2_sjr_casosjr_on_comosupo_id ON sivel2_sjr_casosjr USING btree (comosupo_id);


--
-- Name: index_usuario_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_usuario_on_email ON usuario USING btree (email);


--
-- Name: index_usuario_on_regionsjr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_usuario_on_regionsjr_id ON usuario USING btree (oficina_id);


--
-- Name: index_usuario_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_usuario_on_reset_password_token ON usuario USING btree (reset_password_token);


--
-- Name: sip_busca_mundep; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sip_busca_mundep ON sip_mundep USING gin (mundep);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: usuario_nusuario; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX usuario_nusuario ON usuario USING btree (nusuario);


--
-- Name: cor1440_gen_actividad actividad_regionsjr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad
    ADD CONSTRAINT actividad_regionsjr_id_fkey FOREIGN KEY (oficina_id) REFERENCES sip_oficina(id);


--
-- Name: sivel2_gen_acto acto_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_acto acto_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES sivel2_gen_categoria(id);


--
-- Name: sivel2_gen_acto acto_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES sip_persona(id);


--
-- Name: sivel2_gen_acto acto_id_presponsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT acto_id_presponsable_fkey FOREIGN KEY (id_presponsable) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_gen_actocolectivo actocolectivo_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actocolectivo
    ADD CONSTRAINT actocolectivo_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_actocolectivo actocolectivo_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actocolectivo
    ADD CONSTRAINT actocolectivo_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES sivel2_gen_categoria(id);


--
-- Name: sivel2_gen_actocolectivo actocolectivo_id_grupoper_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actocolectivo
    ADD CONSTRAINT actocolectivo_id_grupoper_fkey FOREIGN KEY (id_grupoper) REFERENCES sivel2_gen_grupoper(id);


--
-- Name: sivel2_gen_actocolectivo actocolectivo_id_presponsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_actocolectivo
    ADD CONSTRAINT actocolectivo_id_presponsable_fkey FOREIGN KEY (id_presponsable) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_sjr_actosjr actosjr_desplazamiento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_actosjr
    ADD CONSTRAINT actosjr_desplazamiento_id_fkey FOREIGN KEY (desplazamiento_id) REFERENCES sivel2_sjr_desplazamiento(id);


--
-- Name: sivel2_sjr_actosjr actosjr_id_acto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_actosjr
    ADD CONSTRAINT actosjr_id_acto_fkey FOREIGN KEY (id_acto) REFERENCES sivel2_gen_acto(id);


--
-- Name: sivel2_gen_anexo_caso anexo_fuenteprensa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_anexo_caso
    ADD CONSTRAINT anexo_fuenteprensa_id_fkey FOREIGN KEY (fuenteprensa_id) REFERENCES sip_fuenteprensa(id);


--
-- Name: sivel2_gen_anexo_caso anexo_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_anexo_caso
    ADD CONSTRAINT anexo_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_anexo_caso anexo_id_fotra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_anexo_caso
    ADD CONSTRAINT anexo_id_fotra_fkey FOREIGN KEY (id_fotra) REFERENCES sivel2_gen_fotra(id);


--
-- Name: sivel2_gen_antecedente_caso antecedente_caso_id_antecedente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_caso
    ADD CONSTRAINT antecedente_caso_id_antecedente_fkey FOREIGN KEY (id_antecedente) REFERENCES sivel2_gen_antecedente(id);


--
-- Name: sivel2_gen_antecedente_caso antecedente_caso_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_caso
    ADD CONSTRAINT antecedente_caso_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_antecedente_victimacolectiva antecedente_comunidad_id_antecedente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victimacolectiva
    ADD CONSTRAINT antecedente_comunidad_id_antecedente_fkey FOREIGN KEY (id_antecedente) REFERENCES sivel2_gen_antecedente(id);


--
-- Name: sivel2_gen_antecedente_victima antecedente_victima_id_antecedente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT antecedente_victima_id_antecedente_fkey FOREIGN KEY (id_antecedente) REFERENCES sivel2_gen_antecedente(id);


--
-- Name: sivel2_gen_antecedente_victima antecedente_victima_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT antecedente_victima_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_antecedente_victima antecedente_victima_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT antecedente_victima_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES sip_persona(id);


--
-- Name: sivel2_gen_antecedente_victima antecedente_victima_id_victima_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT antecedente_victima_id_victima_fkey FOREIGN KEY (id_victima) REFERENCES sivel2_gen_victima(id);


--
-- Name: sivel2_sjr_aslegal_respuesta aslegal_respuesta_id_aslegal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_aslegal_respuesta
    ADD CONSTRAINT aslegal_respuesta_id_aslegal_fkey FOREIGN KEY (id_aslegal) REFERENCES sivel2_sjr_aslegal(id);


--
-- Name: sivel2_sjr_aslegal_respuesta aslegal_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_aslegal_respuesta
    ADD CONSTRAINT aslegal_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: aspsicosocial_respuesta aspsicosocial_respuesta_id_aspsicosocial_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aspsicosocial_respuesta
    ADD CONSTRAINT aspsicosocial_respuesta_id_aspsicosocial_fkey FOREIGN KEY (id_aspsicosocial) REFERENCES aspsicosocial(id);


--
-- Name: aspsicosocial_respuesta aspsicosocial_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aspsicosocial_respuesta
    ADD CONSTRAINT aspsicosocial_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sivel2_sjr_ayudaestado_respuesta ayudaestado_respuesta_id_ayudaestado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado_respuesta
    ADD CONSTRAINT ayudaestado_respuesta_id_ayudaestado_fkey FOREIGN KEY (id_ayudaestado) REFERENCES sivel2_sjr_ayudaestado(id);


--
-- Name: sivel2_sjr_ayudaestado_respuesta ayudaestado_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado_respuesta
    ADD CONSTRAINT ayudaestado_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sivel2_sjr_ayudasjr_respuesta ayudasjr_respuesta_id_ayudasjr_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr_respuesta
    ADD CONSTRAINT ayudasjr_respuesta_id_ayudasjr_fkey FOREIGN KEY (id_ayudasjr) REFERENCES sivel2_sjr_ayudasjr(id);


--
-- Name: sivel2_sjr_ayudasjr_respuesta ayudasjr_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr_respuesta
    ADD CONSTRAINT ayudasjr_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_id_caso_presponsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_id_caso_presponsable_fkey FOREIGN KEY (id_caso_presponsable) REFERENCES sivel2_gen_caso_presponsable(id);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES sivel2_gen_categoria(id);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_id_presponsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_id_presponsable_fkey FOREIGN KEY (id_presponsable) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_gen_caso_categoria_presponsable caso_categoria_presponsable_id_tviolencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_categoria_presponsable
    ADD CONSTRAINT caso_categoria_presponsable_id_tviolencia_fkey FOREIGN KEY (id_tviolencia) REFERENCES sivel2_gen_tviolencia(id);


--
-- Name: sivel2_gen_caso_contexto caso_contexto_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_contexto
    ADD CONSTRAINT caso_contexto_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_contexto caso_contexto_id_contexto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_contexto
    ADD CONSTRAINT caso_contexto_id_contexto_fkey FOREIGN KEY (id_contexto) REFERENCES sivel2_gen_contexto(id);


--
-- Name: sivel2_gen_caso_etiqueta caso_etiqueta_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_etiqueta
    ADD CONSTRAINT caso_etiqueta_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_etiqueta caso_etiqueta_id_etiqueta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_etiqueta
    ADD CONSTRAINT caso_etiqueta_id_etiqueta_fkey FOREIGN KEY (id_etiqueta) REFERENCES sip_etiqueta(id);


--
-- Name: sivel2_gen_caso_etiqueta caso_etiqueta_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_etiqueta
    ADD CONSTRAINT caso_etiqueta_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES usuario(id);


--
-- Name: sivel2_gen_caso_fotra caso_fotra_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fotra
    ADD CONSTRAINT caso_fotra_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_fotra caso_fotra_id_fotra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fotra
    ADD CONSTRAINT caso_fotra_id_fotra_fkey FOREIGN KEY (id_fotra) REFERENCES sivel2_gen_fotra(id);


--
-- Name: sivel2_gen_caso_frontera caso_frontera_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_frontera
    ADD CONSTRAINT caso_frontera_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_frontera caso_frontera_id_frontera_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_frontera
    ADD CONSTRAINT caso_frontera_id_frontera_fkey FOREIGN KEY (id_frontera) REFERENCES sivel2_gen_frontera(id);


--
-- Name: sivel2_gen_caso_usuario caso_funcionario_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_usuario
    ADD CONSTRAINT caso_funcionario_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_presponsable caso_presponsable_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_presponsable
    ADD CONSTRAINT caso_presponsable_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_presponsable caso_presponsable_id_presponsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_presponsable
    ADD CONSTRAINT caso_presponsable_id_presponsable_fkey FOREIGN KEY (id_presponsable) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_gen_caso_region caso_region_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_region
    ADD CONSTRAINT caso_region_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_region caso_region_id_region_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_region
    ADD CONSTRAINT caso_region_id_region_fkey FOREIGN KEY (id_region) REFERENCES sivel2_gen_region(id);


--
-- Name: sivel2_gen_caso_usuario caso_usuario_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_usuario
    ADD CONSTRAINT caso_usuario_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_caso_usuario caso_usuario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_usuario
    ADD CONSTRAINT caso_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES usuario(id);


--
-- Name: sivel2_sjr_casosjr casosjr_asesor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_asesor_fkey FOREIGN KEY (asesor) REFERENCES usuario(id);


--
-- Name: sivel2_sjr_casosjr casosjr_categoriaref_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_categoriaref_fkey FOREIGN KEY (categoriaref) REFERENCES sivel2_gen_categoria(id);


--
-- Name: sivel2_sjr_casosjr casosjr_comosupo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_comosupo_id_fkey FOREIGN KEY (comosupo_id) REFERENCES sivel2_sjr_comosupo(id);


--
-- Name: sivel2_sjr_casosjr casosjr_contacto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_contacto_fkey FOREIGN KEY (contacto) REFERENCES sip_persona(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_llegada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_llegada_fkey FOREIGN KEY (id_llegada) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_proteccion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_proteccion_fkey FOREIGN KEY (id_proteccion) REFERENCES sivel2_sjr_proteccion(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_regionsjr_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_regionsjr_fkey FOREIGN KEY (oficina_id) REFERENCES sip_oficina(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_salida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_salida_fkey FOREIGN KEY (id_salida) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_casosjr casosjr_id_statusmigratorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_casosjr
    ADD CONSTRAINT casosjr_id_statusmigratorio_fkey FOREIGN KEY (id_statusmigratorio) REFERENCES sivel2_sjr_statusmigratorio(id);


--
-- Name: sivel2_gen_categoria categoria_contadaen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_categoria
    ADD CONSTRAINT categoria_contadaen_fkey FOREIGN KEY (contadaen) REFERENCES sivel2_gen_categoria(id);


--
-- Name: sip_clase clase_id_tclase_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_clase
    ADD CONSTRAINT clase_id_tclase_fkey FOREIGN KEY (id_tclase) REFERENCES sip_tclase(id);


--
-- Name: sivel2_gen_filiacion_victimacolectiva comunidad_filiacion_id_filiacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_filiacion_victimacolectiva
    ADD CONSTRAINT comunidad_filiacion_id_filiacion_fkey FOREIGN KEY (id_filiacion) REFERENCES sivel2_gen_filiacion(id);


--
-- Name: sivel2_gen_organizacion_victimacolectiva comunidad_organizacion_id_organizacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_organizacion_victimacolectiva
    ADD CONSTRAINT comunidad_organizacion_id_organizacion_fkey FOREIGN KEY (id_organizacion) REFERENCES sivel2_gen_organizacion(id);


--
-- Name: sivel2_gen_profesion_victimacolectiva comunidad_profesion_id_profesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_profesion_victimacolectiva
    ADD CONSTRAINT comunidad_profesion_id_profesion_fkey FOREIGN KEY (id_profesion) REFERENCES sivel2_gen_profesion(id);


--
-- Name: sivel2_gen_rangoedad_victimacolectiva comunidad_rangoedad_id_rangoedad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_rangoedad_victimacolectiva
    ADD CONSTRAINT comunidad_rangoedad_id_rangoedad_fkey FOREIGN KEY (id_rangoedad) REFERENCES sivel2_gen_rangoedad(id);


--
-- Name: sivel2_gen_sectorsocial_victimacolectiva comunidad_sectorsocial_id_sector_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_sectorsocial_victimacolectiva
    ADD CONSTRAINT comunidad_sectorsocial_id_sector_fkey FOREIGN KEY (id_sectorsocial) REFERENCES sivel2_gen_sectorsocial(id);


--
-- Name: sivel2_gen_sectorsocial_victimacolectiva comunidad_sectorsocial_id_sectorsocial_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_sectorsocial_victimacolectiva
    ADD CONSTRAINT comunidad_sectorsocial_id_sectorsocial_fkey FOREIGN KEY (id_sectorsocial) REFERENCES sivel2_gen_sectorsocial(id);


--
-- Name: sivel2_gen_victimacolectiva_vinculoestado comunidad_vinculoestado_id_vinculoestado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva_vinculoestado
    ADD CONSTRAINT comunidad_vinculoestado_id_vinculoestado_fkey FOREIGN KEY (id_vinculoestado) REFERENCES sivel2_gen_vinculoestado(id);


--
-- Name: cor1440_gen_actividad_actividadtipo cor1440_gen_actividad_actividadtipo_actividad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_actividadtipo
    ADD CONSTRAINT cor1440_gen_actividad_actividadtipo_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES cor1440_gen_actividad(id);


--
-- Name: cor1440_gen_actividad_actividadtipo cor1440_gen_actividad_actividadtipo_actividadtipo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_actividadtipo
    ADD CONSTRAINT cor1440_gen_actividad_actividadtipo_actividadtipo_id_fkey FOREIGN KEY (actividadtipo_id) REFERENCES cor1440_gen_actividadtipo(id);


--
-- Name: sip_departamento departamento_id_pais_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_departamento
    ADD CONSTRAINT departamento_id_pais_fkey FOREIGN KEY (id_pais) REFERENCES sip_pais(id);


--
-- Name: sivel2_sjr_derecho_respuesta derecho_respuesta_id_derecho_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_derecho_respuesta
    ADD CONSTRAINT derecho_respuesta_id_derecho_fkey FOREIGN KEY (id_derecho) REFERENCES sivel2_sjr_derecho(id);


--
-- Name: sivel2_sjr_derecho_respuesta derecho_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_derecho_respuesta
    ADD CONSTRAINT derecho_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_expulsion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_expulsion_fkey FOREIGN KEY (id_expulsion) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_id_expulsion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_id_expulsion_fkey FOREIGN KEY (id_expulsion) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_id_llegada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_id_llegada_fkey FOREIGN KEY (id_llegada) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_id_tipodesp_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_id_tipodesp_fkey FOREIGN KEY (id_tipodesp) REFERENCES sivel2_sjr_tipodesp(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_llegada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_llegada_fkey FOREIGN KEY (id_llegada) REFERENCES sip_ubicacion(id);


--
-- Name: sivel2_sjr_desplazamiento desplazamiento_paisdecl_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_desplazamiento
    ADD CONSTRAINT desplazamiento_paisdecl_fkey FOREIGN KEY (paisdecl) REFERENCES sip_pais(id);


--
-- Name: emprendimiento_respuesta emprendimiento_respuesta_id_emprendimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emprendimiento_respuesta
    ADD CONSTRAINT emprendimiento_respuesta_id_emprendimiento_fkey FOREIGN KEY (id_emprendimiento) REFERENCES emprendimiento(id);


--
-- Name: emprendimiento_respuesta emprendimiento_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emprendimiento_respuesta
    ADD CONSTRAINT emprendimiento_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: evento_motivonodenuncia fk_rails_0561cf5aee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_motivonodenuncia
    ADD CONSTRAINT fk_rails_0561cf5aee FOREIGN KEY (motivonodenuncia_id) REFERENCES motivonodenuncia(id);


--
-- Name: cor1440_gen_financiador_proyectofinanciero fk_rails_0cd09d688c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_financiador_proyectofinanciero
    ADD CONSTRAINT fk_rails_0cd09d688c FOREIGN KEY (financiador_id) REFERENCES cor1440_gen_financiador(id);


--
-- Name: acompanamiento_evento fk_rails_135b8955e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento_evento
    ADD CONSTRAINT fk_rails_135b8955e2 FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: categoria_eventopresponsable fk_rails_15665aea7a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categoria_eventopresponsable
    ADD CONSTRAINT fk_rails_15665aea7a FOREIGN KEY (eventopresponsable_id) REFERENCES eventopresponsable(id);


--
-- Name: sivel2_sjr_progestado_derecho fk_rails_1b764c2a63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado_derecho
    ADD CONSTRAINT fk_rails_1b764c2a63 FOREIGN KEY (derecho_id) REFERENCES sivel2_sjr_derecho(id);


--
-- Name: actoevento fk_rails_1d7193a924; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY actoevento
    ADD CONSTRAINT fk_rails_1d7193a924 FOREIGN KEY (categoria_id) REFERENCES sivel2_gen_categoria(id);


--
-- Name: heb412_gen_campohc fk_rails_1e5f26c999; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campohc
    ADD CONSTRAINT fk_rails_1e5f26c999 FOREIGN KEY (doc_id) REFERENCES heb412_gen_doc(id);


--
-- Name: acompanamientorec_evento fk_rails_207c5a7932; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamientorec_evento
    ADD CONSTRAINT fk_rails_207c5a7932 FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: cor1440_gen_informe fk_rails_294895347e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT fk_rails_294895347e FOREIGN KEY (filtroproyecto) REFERENCES cor1440_gen_proyecto(id);


--
-- Name: cor1440_gen_informe fk_rails_2bd685d2b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT fk_rails_2bd685d2b3 FOREIGN KEY (filtroresponsable) REFERENCES usuario(id);


--
-- Name: heb412_gen_doc fk_rails_2dd6d3dac3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_doc
    ADD CONSTRAINT fk_rails_2dd6d3dac3 FOREIGN KEY (dirpapa) REFERENCES heb412_gen_doc(id);


--
-- Name: cor1440_gen_actividad_proyecto fk_rails_395faa0882; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyecto
    ADD CONSTRAINT fk_rails_395faa0882 FOREIGN KEY (actividad_id) REFERENCES cor1440_gen_actividad(id);


--
-- Name: evento_motivonodenuncia fk_rails_3e3dd2d2ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_motivonodenuncia
    ADD CONSTRAINT fk_rails_3e3dd2d2ca FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: sivel2_sjr_ayudasjr_derecho fk_rails_3f9c573526; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr_derecho
    ADD CONSTRAINT fk_rails_3f9c573526 FOREIGN KEY (ayudasjr_id) REFERENCES sivel2_sjr_ayudasjr(id);


--
-- Name: cor1440_gen_informe fk_rails_40cb623d50; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT fk_rails_40cb623d50 FOREIGN KEY (filtroproyectofinanciero) REFERENCES cor1440_gen_proyectofinanciero(id);


--
-- Name: actoevento fk_rails_4246a1a735; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY actoevento
    ADD CONSTRAINT fk_rails_4246a1a735 FOREIGN KEY (presponsable_id) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: cor1440_gen_actividad fk_rails_4426fc905e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad
    ADD CONSTRAINT fk_rails_4426fc905e FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- Name: cor1440_gen_actividad_sip_anexo fk_rails_49ec1ae361; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_sip_anexo
    ADD CONSTRAINT fk_rails_49ec1ae361 FOREIGN KEY (anexo_id) REFERENCES sip_anexo(id);


--
-- Name: sivel2_sjr_ayudaestado_derecho fk_rails_50f4b271e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado_derecho
    ADD CONSTRAINT fk_rails_50f4b271e8 FOREIGN KEY (derecho_id) REFERENCES sivel2_sjr_derecho(id);


--
-- Name: cor1440_gen_actividad_proyectofinanciero fk_rails_524486e06b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyectofinanciero
    ADD CONSTRAINT fk_rails_524486e06b FOREIGN KEY (proyectofinanciero_id) REFERENCES cor1440_gen_proyectofinanciero(id);


--
-- Name: acompanamiento_evento fk_rails_5564d830d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento_evento
    ADD CONSTRAINT fk_rails_5564d830d8 FOREIGN KEY (acompanamiento_id) REFERENCES acompanamiento(id);


--
-- Name: sivel2_gen_acto fk_rails_58d7621b3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_acto
    ADD CONSTRAINT fk_rails_58d7621b3b FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: sivel2_sjr_motivosjr_derecho fk_rails_617626a841; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr_derecho
    ADD CONSTRAINT fk_rails_617626a841 FOREIGN KEY (motivosjr_id) REFERENCES sivel2_sjr_motivosjr(id);


--
-- Name: sivel2_gen_combatiente fk_rails_6485d06d37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_6485d06d37 FOREIGN KEY (id_vinculoestado) REFERENCES sivel2_gen_vinculoestado(id);


--
-- Name: sivel2_sjr_ayudasjr_derecho fk_rails_6bf41923e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudasjr_derecho
    ADD CONSTRAINT fk_rails_6bf41923e4 FOREIGN KEY (derecho_id) REFERENCES sivel2_sjr_derecho(id);


--
-- Name: sivel2_sjr_ayudaestado_derecho fk_rails_863c4c40a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_ayudaestado_derecho
    ADD CONSTRAINT fk_rails_863c4c40a3 FOREIGN KEY (ayudaestado_id) REFERENCES sivel2_sjr_ayudaestado(id);


--
-- Name: acompanamientorec_evento fk_rails_935f78da72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamientorec_evento
    ADD CONSTRAINT fk_rails_935f78da72 FOREIGN KEY (acompanamiento_id) REFERENCES acompanamiento(id);


--
-- Name: sivel2_gen_combatiente fk_rails_95f4a0b8f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_95f4a0b8f6 FOREIGN KEY (id_profesion) REFERENCES sivel2_gen_profesion(id);


--
-- Name: evento fk_rails_983eca7e75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT fk_rails_983eca7e75 FOREIGN KEY (municipio_id) REFERENCES sip_municipio(id);


--
-- Name: sivel2_sjr_motivosjr_derecho fk_rails_9cf4a23afe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr_derecho
    ADD CONSTRAINT fk_rails_9cf4a23afe FOREIGN KEY (derecho_id) REFERENCES sivel2_sjr_derecho(id);


--
-- Name: sivel2_sjr_victimasjr fk_rails_9ffea98e74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT fk_rails_9ffea98e74 FOREIGN KEY (departamentores_id) REFERENCES sip_departamento(id);


--
-- Name: evento_relacionprvic fk_rails_a681c0f7e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_relacionprvic
    ADD CONSTRAINT fk_rails_a681c0f7e2 FOREIGN KEY (relacionprvic_id) REFERENCES relacionprvic(id);


--
-- Name: cor1440_gen_actividad_proyectofinanciero fk_rails_a8489e0d62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyectofinanciero
    ADD CONSTRAINT fk_rails_a8489e0d62 FOREIGN KEY (actividad_id) REFERENCES cor1440_gen_actividad(id);


--
-- Name: evento_relacionprvic fk_rails_ab1222755b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_relacionprvic
    ADD CONSTRAINT fk_rails_ab1222755b FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: idioma_victimasjr fk_rails_af399be27d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY idioma_victimasjr
    ADD CONSTRAINT fk_rails_af399be27d FOREIGN KEY (sivel2_sjr_victimasjr_id) REFERENCES sivel2_sjr_victimasjr(id_victima);


--
-- Name: sivel2_gen_combatiente fk_rails_af43e915a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_af43e915a6 FOREIGN KEY (id_filiacion) REFERENCES sivel2_gen_filiacion(id);


--
-- Name: sivel2_sjr_victimasjr fk_rails_b5a91788a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT fk_rails_b5a91788a4 FOREIGN KEY (municipiores_id) REFERENCES sip_municipio(id);


--
-- Name: sivel2_sjr_victimasjr fk_rails_b645b4caf9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT fk_rails_b645b4caf9 FOREIGN KEY (educacionpropia_id) REFERENCES educacionpropia(id);


--
-- Name: tienetierra_victimasjr fk_rails_b6bcd29bac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tienetierra_victimasjr
    ADD CONSTRAINT fk_rails_b6bcd29bac FOREIGN KEY (tienetierra_id) REFERENCES tienetierra(id);


--
-- Name: sivel2_gen_combatiente fk_rails_bfb49597e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_bfb49597e1 FOREIGN KEY (organizacionarmada) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: cor1440_gen_informe fk_rails_c02831dd89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT fk_rails_c02831dd89 FOREIGN KEY (filtroactividadarea) REFERENCES cor1440_gen_actividadarea(id);


--
-- Name: idioma_victimasjr fk_rails_c0a9d93add; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY idioma_victimasjr
    ADD CONSTRAINT fk_rails_c0a9d93add FOREIGN KEY (sivel2_sjr_idioma_id) REFERENCES sivel2_sjr_idioma(id);


--
-- Name: acompanamiento_casosjr fk_rails_c6252a245a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento_casosjr
    ADD CONSTRAINT fk_rails_c6252a245a FOREIGN KEY (acompanamiento_id) REFERENCES acompanamiento(id);


--
-- Name: cor1440_gen_financiador_proyectofinanciero fk_rails_ca93eb04dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_financiador_proyectofinanciero
    ADD CONSTRAINT fk_rails_ca93eb04dc FOREIGN KEY (proyectofinanciero_id) REFERENCES cor1440_gen_proyectofinanciero(id);


--
-- Name: cor1440_gen_actividad_sip_anexo fk_rails_cc9d44f9de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_sip_anexo
    ADD CONSTRAINT fk_rails_cc9d44f9de FOREIGN KEY (actividad_id) REFERENCES cor1440_gen_actividad(id);


--
-- Name: tienetierra_victimasjr fk_rails_ccc78f721a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tienetierra_victimasjr
    ADD CONSTRAINT fk_rails_ccc78f721a FOREIGN KEY (sivel2_sjr_victimasjr_id) REFERENCES sivel2_sjr_victimasjr(id_victima);


--
-- Name: cor1440_gen_actividad_proyecto fk_rails_cf5d592625; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_actividad_proyecto
    ADD CONSTRAINT fk_rails_cf5d592625 FOREIGN KEY (proyecto_id) REFERENCES cor1440_gen_proyecto(id);


--
-- Name: eventopresponsable fk_rails_d608eaa15d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eventopresponsable
    ADD CONSTRAINT fk_rails_d608eaa15d FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: cor1440_gen_informe fk_rails_daf0af8605; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_informe
    ADD CONSTRAINT fk_rails_daf0af8605 FOREIGN KEY (filtrooficina) REFERENCES sip_oficina(id);


--
-- Name: sivel2_sjr_victimasjr fk_rails_db4e1db76f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT fk_rails_db4e1db76f FOREIGN KEY (religion_id) REFERENCES religion(id);


--
-- Name: heb412_gen_campoplantillahcm fk_rails_e0e38e0782; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heb412_gen_campoplantillahcm
    ADD CONSTRAINT fk_rails_e0e38e0782 FOREIGN KEY (plantillahcm_id) REFERENCES heb412_gen_plantillahcm(id);


--
-- Name: sivel2_gen_combatiente fk_rails_e2d01a5a99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_e2d01a5a99 FOREIGN KEY (id_sectorsocial) REFERENCES sivel2_gen_sectorsocial(id);


--
-- Name: evento fk_rails_e5971f991a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT fk_rails_e5971f991a FOREIGN KEY (motivonodenuncia_id) REFERENCES motivonodenuncia(id);


--
-- Name: sivel2_sjr_progestado_derecho fk_rails_e8dedd8c1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado_derecho
    ADD CONSTRAINT fk_rails_e8dedd8c1d FOREIGN KEY (progestado_id) REFERENCES sivel2_sjr_progestado(id);


--
-- Name: acompanamiento_casosjr fk_rails_efad5b94f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acompanamiento_casosjr
    ADD CONSTRAINT fk_rails_efad5b94f4 FOREIGN KEY (sivel2_sjr_casosjr_id) REFERENCES sivel2_sjr_casosjr(id_caso);


--
-- Name: sivel2_gen_combatiente fk_rails_f0cf2a7bec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_f0cf2a7bec FOREIGN KEY (id_resagresion) REFERENCES sivel2_gen_resagresion(id);


--
-- Name: evento fk_rails_f10bf1ea91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT fk_rails_f10bf1ea91 FOREIGN KEY (departamento_id) REFERENCES sip_departamento(id);


--
-- Name: sivel2_gen_antecedente_combatiente fk_rails_f305297325; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_combatiente
    ADD CONSTRAINT fk_rails_f305297325 FOREIGN KEY (id_combatiente) REFERENCES sivel2_gen_combatiente(id);


--
-- Name: categoria_eventopresponsable fk_rails_f6afa1e144; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categoria_eventopresponsable
    ADD CONSTRAINT fk_rails_f6afa1e144 FOREIGN KEY (categoria_id) REFERENCES sivel2_gen_categoria(id);


--
-- Name: eventopresponsable fk_rails_f7655f6551; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eventopresponsable
    ADD CONSTRAINT fk_rails_f7655f6551 FOREIGN KEY (presponsable_id) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_gen_combatiente fk_rails_f77dda7a40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_f77dda7a40 FOREIGN KEY (id_organizacion) REFERENCES sivel2_gen_organizacion(id);


--
-- Name: actoevento fk_rails_f8f93ca7e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY actoevento
    ADD CONSTRAINT fk_rails_f8f93ca7e5 FOREIGN KEY (evento_id) REFERENCES evento(id);


--
-- Name: sivel2_gen_combatiente fk_rails_fb02819ec4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_combatiente
    ADD CONSTRAINT fk_rails_fb02819ec4 FOREIGN KEY (id_rangoedad) REFERENCES sivel2_gen_rangoedad(id);


--
-- Name: sivel2_gen_antecedente_combatiente fk_rails_fc1811169b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_combatiente
    ADD CONSTRAINT fk_rails_fc1811169b FOREIGN KEY (id_antecedente) REFERENCES sivel2_gen_antecedente(id);


--
-- Name: cor1440_gen_proyectofinanciero lf_proyectofinanciero_responsable; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cor1440_gen_proyectofinanciero
    ADD CONSTRAINT lf_proyectofinanciero_responsable FOREIGN KEY (responsable_id) REFERENCES usuario(id);


--
-- Name: sivel2_sjr_motivosjr_respuesta motivosjr_respuesta_id_motivosjr_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr_respuesta
    ADD CONSTRAINT motivosjr_respuesta_id_motivosjr_fkey FOREIGN KEY (id_motivosjr) REFERENCES sivel2_sjr_motivosjr(id);


--
-- Name: sivel2_sjr_motivosjr_respuesta motivosjr_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_motivosjr_respuesta
    ADD CONSTRAINT motivosjr_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sip_persona persona_id_pais_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT persona_id_pais_fkey FOREIGN KEY (id_pais) REFERENCES sip_pais(id);


--
-- Name: sip_persona persona_nacionalde_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT persona_nacionalde_fkey FOREIGN KEY (nacionalde) REFERENCES sip_pais(id);


--
-- Name: sip_persona persona_tdocumento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT persona_tdocumento_id_fkey FOREIGN KEY (tdocumento_id) REFERENCES sip_tdocumento(id);


--
-- Name: sip_persona_trelacion persona_trelacion_id_trelacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT persona_trelacion_id_trelacion_fkey FOREIGN KEY (id_trelacion) REFERENCES sip_trelacion(id);


--
-- Name: sip_persona_trelacion persona_trelacion_persona1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT persona_trelacion_persona1_fkey FOREIGN KEY (persona1) REFERENCES sip_persona(id);


--
-- Name: sip_persona_trelacion persona_trelacion_persona2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona_trelacion
    ADD CONSTRAINT persona_trelacion_persona2_fkey FOREIGN KEY (persona2) REFERENCES sip_persona(id);


--
-- Name: sivel2_gen_presponsable presponsable_papa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_presponsable
    ADD CONSTRAINT presponsable_papa_fkey FOREIGN KEY (papa) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_sjr_progestado_respuesta progestado_respuesta_id_progestado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado_respuesta
    ADD CONSTRAINT progestado_respuesta_id_progestado_fkey FOREIGN KEY (id_progestado) REFERENCES sivel2_sjr_progestado(id);


--
-- Name: sivel2_sjr_progestado_respuesta progestado_respuesta_id_respuesta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_progestado_respuesta
    ADD CONSTRAINT progestado_respuesta_id_respuesta_fkey FOREIGN KEY (id_respuesta) REFERENCES sivel2_sjr_respuesta(id);


--
-- Name: sivel2_sjr_respuesta respuesta_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_respuesta
    ADD CONSTRAINT respuesta_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_sjr_casosjr(id_caso);


--
-- Name: sivel2_sjr_respuesta respuesta_id_personadesea_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_respuesta
    ADD CONSTRAINT respuesta_id_personadesea_fkey FOREIGN KEY (id_personadesea) REFERENCES sivel2_sjr_personadesea(id);


--
-- Name: sip_clase sip_clase_id_municipio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_clase
    ADD CONSTRAINT sip_clase_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES sip_municipio(id);


--
-- Name: sip_municipio sip_municipio_id_departamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_municipio
    ADD CONSTRAINT sip_municipio_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES sip_departamento(id);


--
-- Name: sip_persona sip_persona_id_clase_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT sip_persona_id_clase_fkey FOREIGN KEY (id_clase) REFERENCES sip_clase(id);


--
-- Name: sip_persona sip_persona_id_departamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT sip_persona_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES sip_departamento(id);


--
-- Name: sip_persona sip_persona_id_municipio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_persona
    ADD CONSTRAINT sip_persona_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES sip_municipio(id);


--
-- Name: sip_ubicacion sip_ubicacion_id_clase_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT sip_ubicacion_id_clase_fkey FOREIGN KEY (id_clase) REFERENCES sip_clase(id);


--
-- Name: sip_ubicacion sip_ubicacion_id_departamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT sip_ubicacion_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES sip_departamento(id);


--
-- Name: sip_ubicacion sip_ubicacion_id_municipio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT sip_ubicacion_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES sip_municipio(id);


--
-- Name: sivel2_gen_antecedente_victimacolectiva sivel2_gen_antecedente_victimacolectiv_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victimacolectiva
    ADD CONSTRAINT sivel2_gen_antecedente_victimacolectiv_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_caso_fotra sivel2_gen_caso_fotra_anexo_caso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fotra
    ADD CONSTRAINT sivel2_gen_caso_fotra_anexo_caso_id_fkey FOREIGN KEY (anexo_caso_id) REFERENCES sivel2_gen_anexo_caso(id);


--
-- Name: sivel2_gen_caso_fuenteprensa sivel2_gen_caso_fuenteprensa_anexo_caso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fuenteprensa
    ADD CONSTRAINT sivel2_gen_caso_fuenteprensa_anexo_caso_id_fkey FOREIGN KEY (anexo_caso_id) REFERENCES sivel2_gen_anexo_caso(id);


--
-- Name: sivel2_gen_caso_fuenteprensa sivel2_gen_caso_fuenteprensa_fuenteprensa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fuenteprensa
    ADD CONSTRAINT sivel2_gen_caso_fuenteprensa_fuenteprensa_id_fkey FOREIGN KEY (fuenteprensa_id) REFERENCES sip_fuenteprensa(id);


--
-- Name: sivel2_gen_caso_fuenteprensa sivel2_gen_caso_fuenteprensa_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_caso_fuenteprensa
    ADD CONSTRAINT sivel2_gen_caso_fuenteprensa_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_categoria sivel2_gen_categoria_supracategoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_categoria
    ADD CONSTRAINT sivel2_gen_categoria_supracategoria_id_fkey FOREIGN KEY (supracategoria_id) REFERENCES sivel2_gen_supracategoria(id);


--
-- Name: sivel2_gen_filiacion_victimacolectiva sivel2_gen_filiacion_victimacolectiva_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_filiacion_victimacolectiva
    ADD CONSTRAINT sivel2_gen_filiacion_victimacolectiva_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_organizacion_victimacolectiva sivel2_gen_organizacion_victimacolecti_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_organizacion_victimacolectiva
    ADD CONSTRAINT sivel2_gen_organizacion_victimacolecti_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_profesion_victimacolectiva sivel2_gen_profesion_victimacolectiva_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_profesion_victimacolectiva
    ADD CONSTRAINT sivel2_gen_profesion_victimacolectiva_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_rangoedad_victimacolectiva sivel2_gen_rangoedad_victimacolectiva_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_rangoedad_victimacolectiva
    ADD CONSTRAINT sivel2_gen_rangoedad_victimacolectiva_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_sectorsocial_victimacolectiva sivel2_gen_sectorsocial_victimacolecti_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_sectorsocial_victimacolectiva
    ADD CONSTRAINT sivel2_gen_sectorsocial_victimacolecti_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_victimacolectiva_vinculoestado sivel2_gen_victimacolectiva_vinculoest_victimacolectiva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva_vinculoestado
    ADD CONSTRAINT sivel2_gen_victimacolectiva_vinculoest_victimacolectiva_id_fkey FOREIGN KEY (victimacolectiva_id) REFERENCES sivel2_gen_victimacolectiva(id);


--
-- Name: sivel2_gen_supracategoria supracategoria_id_tviolencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_supracategoria
    ADD CONSTRAINT supracategoria_id_tviolencia_fkey FOREIGN KEY (id_tviolencia) REFERENCES sivel2_gen_tviolencia(id);


--
-- Name: sip_trelacion trelacion_inverso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_trelacion
    ADD CONSTRAINT trelacion_inverso_fkey FOREIGN KEY (inverso) REFERENCES sip_trelacion(id);


--
-- Name: sip_ubicacion ubicacion_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT ubicacion_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sip_ubicacion ubicacion_id_pais_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT ubicacion_id_pais_fkey FOREIGN KEY (id_pais) REFERENCES sip_pais(id);


--
-- Name: sip_ubicacion ubicacion_id_tsitio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sip_ubicacion
    ADD CONSTRAINT ubicacion_id_tsitio_fkey FOREIGN KEY (id_tsitio) REFERENCES sip_tsitio(id);


--
-- Name: sivel2_gen_antecedente_victima victima_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_antecedente_victima
    ADD CONSTRAINT victima_fkey FOREIGN KEY (id_caso, id_persona) REFERENCES sivel2_gen_victima(id_caso, id_persona);


--
-- Name: sivel2_gen_victima victima_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_victima victima_id_etnia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_etnia_fkey FOREIGN KEY (id_etnia) REFERENCES sivel2_gen_etnia(id);


--
-- Name: sivel2_gen_victima victima_id_iglesia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_iglesia_fkey FOREIGN KEY (id_iglesia) REFERENCES sivel2_gen_iglesia(id);


--
-- Name: sivel2_gen_victima victima_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES sip_persona(id);


--
-- Name: sivel2_gen_victima victima_id_profesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_profesion_fkey FOREIGN KEY (id_profesion) REFERENCES sivel2_gen_profesion(id);


--
-- Name: sivel2_gen_victima victima_id_rangoedad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_rangoedad_fkey FOREIGN KEY (id_rangoedad) REFERENCES sivel2_gen_rangoedad(id);


--
-- Name: sivel2_gen_victima victima_id_sectorsocial_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_id_sectorsocial_fkey FOREIGN KEY (id_sectorsocial) REFERENCES sivel2_gen_sectorsocial(id);


--
-- Name: sivel2_gen_victima victima_organizacionarmada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victima
    ADD CONSTRAINT victima_organizacionarmada_fkey FOREIGN KEY (organizacionarmada) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_gen_victimacolectiva victimacolectiva_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT victimacolectiva_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES sivel2_gen_caso(id);


--
-- Name: sivel2_gen_victimacolectiva victimacolectiva_id_grupoper_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT victimacolectiva_id_grupoper_fkey FOREIGN KEY (id_grupoper) REFERENCES sivel2_gen_grupoper(id);


--
-- Name: sivel2_gen_victimacolectiva victimacolectiva_organizacionarmada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_gen_victimacolectiva
    ADD CONSTRAINT victimacolectiva_organizacionarmada_fkey FOREIGN KEY (organizacionarmada) REFERENCES sivel2_gen_presponsable(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_actividadoficio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_actividadoficio_fkey FOREIGN KEY (id_actividadoficio) REFERENCES sivel2_gen_actividadoficio(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_escolaridad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_escolaridad_fkey FOREIGN KEY (id_escolaridad) REFERENCES sivel2_gen_escolaridad(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_estadocivil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_estadocivil_fkey FOREIGN KEY (id_estadocivil) REFERENCES sivel2_gen_estadocivil(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_maternidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_maternidad_fkey FOREIGN KEY (id_maternidad) REFERENCES sivel2_gen_maternidad(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_pais_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_pais_fkey FOREIGN KEY (id_pais) REFERENCES sip_pais(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_rolfamilia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_rolfamilia_fkey FOREIGN KEY (id_rolfamilia) REFERENCES sivel2_sjr_rolfamilia(id);


--
-- Name: sivel2_sjr_victimasjr victimasjr_id_victima_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sivel2_sjr_victimasjr
    ADD CONSTRAINT victimasjr_id_victima_fkey FOREIGN KEY (id_victima) REFERENCES sivel2_gen_victima(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES
('20131128151014'),
('20131204135932'),
('20131204140000'),
('20131204143718'),
('20131204183530'),
('20131205233111'),
('20131206081531'),
('20131210221541'),
('20131220103409'),
('20131223175141'),
('20140117212555'),
('20140129151136'),
('20140207102709'),
('20140207102739'),
('20140211162355'),
('20140211164659'),
('20140211172443'),
('20140217100541'),
('20140313012209'),
('20140317121823'),
('20140514142421'),
('20140518120059'),
('20140527110223'),
('20140528043115'),
('20140611110441'),
('20140611111020'),
('20140613044320'),
('20140613200951'),
('20140620112004'),
('20140704035033'),
('20140804194616'),
('20140804200235'),
('20140804202100'),
('20140804202101'),
('20140804202958'),
('20140804210000'),
('20140805030341'),
('20140814184537'),
('20140815111351'),
('20140815111352'),
('20140815121224'),
('20140815123542'),
('20140815124157'),
('20140815124606'),
('20140827142659'),
('20140901105741'),
('20140901106000'),
('20140902101425'),
('20140904033941'),
('20140904211823'),
('20140904213327'),
('20140905121420'),
('20140909141336'),
('20140909165233'),
('20140918115412'),
('20140922102737'),
('20140922110956'),
('20141002140242'),
('20141111102451'),
('20141111203313'),
('20141112111129'),
('20141126085907'),
('20141222174237'),
('20141222174247'),
('20141222174257'),
('20141222174267'),
('20150213114933'),
('20150217185859'),
('20150225140336'),
('20150313153722'),
('20150317084149'),
('20150317084737'),
('20150317090631'),
('20150413000000'),
('20150413160156'),
('20150413160157'),
('20150413160158'),
('20150413160159'),
('20150416074423'),
('20150416090140'),
('20150416095646'),
('20150416101228'),
('20150417071153'),
('20150417180000'),
('20150417180314'),
('20150419000000'),
('20150420104520'),
('20150420110000'),
('20150420125522'),
('20150420153835'),
('20150420200255'),
('20150503120915'),
('20150510125926'),
('20150513112126'),
('20150513130058'),
('20150513130510'),
('20150513160835'),
('20150520115257'),
('20150521092657'),
('20150521181918'),
('20150521191227'),
('20150528100944'),
('20150602094513'),
('20150602095241'),
('20150602104342'),
('20150609094809'),
('20150609094820'),
('20150612203808'),
('20150615024318'),
('20150616095023'),
('20150616100351'),
('20150616100551'),
('20150624200701'),
('20150707164448'),
('20150709203137'),
('20150710012947'),
('20150710114451'),
('20150716085420'),
('20150716171420'),
('20150716192356'),
('20150717101243'),
('20150717161539'),
('20150720115701'),
('20150720120236'),
('20150723233138'),
('20150724000152'),
('20150724003736'),
('20150724024110'),
('20150724032940'),
('20150803082520'),
('20150809032138'),
('20150826000000'),
('20150929112313'),
('20151006105402'),
('20151020203420'),
('20151020203421'),
('20151030094611'),
('20151124110943'),
('20151127102425'),
('20151130101417'),
('20160304104001'),
('20160304104113'),
('20160308213334'),
('20160316093659'),
('20160316094627'),
('20160316100620'),
('20160316100621'),
('20160316100622'),
('20160316100623'),
('20160316100624'),
('20160316100625'),
('20160316100626'),
('20160407102539'),
('20160420080511'),
('20160420202859'),
('20160506015049'),
('20160506022054'),
('20160519195544'),
('20160608060056'),
('20160608082447'),
('20160608084429'),
('20160608084935'),
('20160608090947'),
('20160608093529'),
('20160608103650'),
('20160608105822'),
('20160608114028'),
('20160608115006'),
('20160608121317'),
('20160608121352'),
('20160608122717'),
('20160608122726'),
('20160608205638'),
('20160608211647'),
('20160608213541'),
('20160609113525'),
('20160610063404'),
('20160614023632'),
('20160719195853'),
('20160719214520'),
('20160724160049'),
('20160724164110'),
('20160725123242'),
('20160725125929'),
('20160725131347'),
('20160727033937'),
('20160727103116'),
('20160727133219'),
('20160728125841'),
('20160729110601'),
('20160729114824'),
('20160729124259'),
('20160729125446'),
('20160805103310'),
('20160810095928'),
('20160822112957'),
('20160822113714'),
('20160822154512'),
('20160823144141'),
('20160823150641'),
('20160823164245'),
('20161009111443'),
('20161010152631'),
('20161026110802'),
('20161027233011'),
('20161103080156'),
('20161103081041'),
('20161103083352'),
('20161108102349'),
('20161219110016'),
('20170111104308'),
('20170111104547'),
('20170111110923'),
('20170112104821'),
('20170112111018'),
('20170113101237'),
('20170114022359'),
('20170114040246'),
('20170119013801'),
('20170119034040'),
('20170119034234'),
('20170119035252'),
('20170119143359');


