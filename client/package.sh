if [ -z "$1" ]; then
  echo "I don't know what to package :("
  exit 1
elif [ "$1" = "static" ]; then
  echo "Packing static resources"
  ASSETS=("public")
elif [ "$1" = "build" ]; then
  echo "Packing built resources"
  ASSETS=("public" "dist" "dist-server" "functions" "elm-stuff" "gen" "codegen" "script" "elm-pages.config.mjs")
elif [ "$1" = "all" ]; then
  echo "Packing all resources"
  ASSETS=(".")
else
  echo "Packaging type $1 is unknown."
  exit 1
fi

npm run build

tar -zcvf "client.tar.gz" "${ASSETS[@]}"
