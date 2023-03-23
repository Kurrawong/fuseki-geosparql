#!/bin/sh

export OTEL_RESOURCE_ATTRIBUTES="container.id=$(hostname),${OTEL_RESOURCE_ATTRIBUTES}"

if [ -n "${CONFIG_LOCATION}" ]; then
  curl "${CONFIG_LOCATION}" -s | sudo tee "$FUSEKI_BASE/config.ttl" >/dev/null &&
  sudo chmod 644 "$FUSEKI_BASE/config.ttl" &&
  echo Added config.ttl from "${CONFIG_LOCATION}"
fi

if [ -n "${SHIRO_LOCATION}" ]; then
  curl "${SHIRO_LOCATION}" -s >"$FUSEKI_BASE/template-shiro.ini" &&
    echo Added shiro.ini from "${SHIRO_LOCATION}" &&
    envsubst '$ADMIN_PASSWORD' \
      <"${FUSEKI_BASE}/template-shiro.ini" \
      >"${FUSEKI_BASE}/shiro.ini" &&
    rm "${FUSEKI_BASE}/template-shiro.ini"
else
  envsubst '$ADMIN_PASSWORD' \
    <"${FUSEKI_HOME}/shiro.ini" \
    >"${FUSEKI_BASE}/shiro.ini"
fi

sudo chown fuseki /fuseki/databases

exec
  "${JAVA_HOME}/bin/java" \
  ${JAVA_OPTS} \
  -javaagent:"${FUSEKI_HOME}/otel.jar" \
  -Xshare:off \
  -Dlog4j.configurationFile="${FUSEKI_HOME}/log4j2.properties" \
  -cp "${FUSEKI_HOME}/fuseki-server.jar" \
  org.apache.jena.fuseki.cmd.FusekiCmd
