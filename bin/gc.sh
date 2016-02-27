#!/bin/sh
# Hace pruebas, pruebas de regresión, envia a github y sube a heroku

grep "^ *gem.*sip.*,.*path:" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye un sip cableado al sistema de archivos"
	exit 1;
} fi;
grep "^ *gem.*sivel2_gen.*,.*path:" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye un sivel2_gen cableado al sistema de archivos"
	exit 1;
} fi;
grep "^ *gem.*sivel2_sjr.*,.*path:" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye un sivel2_sjr cableado al sistema de archivos"
	exit 1;
} fi;
grep "^ *gem.*cor1440_gen.*,.*path:" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye un cor1440_gen cableado al sistema de archivos"
	exit 1;
} fi;
grep "^ *gem.*debugger" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye debugger que heroku no quiere"
	exit 1;
} fi;
grep "^ *gem.*byebug" Gemfile > /dev/null 2> /dev/null
if (test "$?" = "0") then {
	echo "Gemfile incluye byebug que rbx de travis-ci no quiere"
	exit 1;
} fi;


if (test "$SINAC" != "1") then {
	NOKOGIRI_USE_SYSTEM_LIBRARIES=1 MAKE=gmake make=gmake QMAKE=qmake4 bundle update
	if (test "$?" != "0") then {
		exit 1;
	} fi;
} fi;
if (test "$SININS" != "1") then {
	NOKOGIRI_USE_SYSTEM_LIBRARIES=1 MAKE=gmake make=gmake QMAKE=qmake4 bundle install
	if (test "$?" != "0") then {
		exit 1;
	} fi;
} fi;
if (test "$SINMIG" != "1") then {
	(rake db:migrate sip:indices db:structure:dump)
	if (test "$?" != "0") then {
		exit 1;
	} fi;
} fi;

RAILS_ENV=test rake db:drop db:setup db:migrate sip:indices
if (test "$?" != "0") then {
	echo "No puede preparse base de prueba";
	exit 1;
} fi;

RACK_MULTIPART_LIMIT=2048 rspec
if (test "$?" != "0") then {
	echo "No pasaron pruebas";
	exit 1;
} fi;

RAILS_ENV=test rake db:structure:dump
b=`git branch | grep "^*" | sed -e  "s/^* //g"`
git status -s
git commit -a
git push origin ${b}
if (test "$?" != "0") then {
	echo "No pudo subirse el cambio a github";
	exit 1;
} fi;

#git push heroku master
#if (test "$?" != "0") then {
#	echo "No pudo publicarse en heroku";
#	exit 1;
#} fi;

#heroku run rake db:migrate sip:indices