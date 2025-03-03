#!/bin/bash

# Répertoire contenant les séries
base_dir="/volume2/serie"

# Clé API TMDb
api_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx"

# Variables pour le rapport final
total_folders=0
renamed_folders=0
merged_folders=0
manual_check=0
manual_list=()

# Fonction pour obtenir l'année de diffusion et le nom correct d'une série sur TMDb
get_tmdb_info() {
    local series_name="$1"
    local series_id
    local tmdb_title
    local airdate_year

    echo "🔎 Recherche de la série '$series_name' sur TMDb..." >&2

    # Rechercher la série
    result=$(curl -s --get "https://api.themoviedb.org/3/search/tv" --data-urlencode "api_key=$api_key" --data-urlencode "query=$series_name")

    series_id=$(echo "$result" | jq -r '.results[0].id // "null"')
    tmdb_title=$(echo "$result" | jq -r '.results[0].name // "null"')

    if [[ "$series_id" =~ ^[0-9]+$ && "$tmdb_title" != "null" ]]; then
        echo "✅ Série trouvée : $tmdb_title (ID: $series_id)" >&2

        airdate_year=$(curl -s "https://api.themoviedb.org/3/tv/$series_id?api_key=$api_key" | jq -r '.first_air_date // "0000-00-00"' | cut -d'-' -f1)

        if [[ ! "$airdate_year" =~ ^[0-9]{4}$ ]]; then
            airdate_year="Inconnu"
        fi

        echo "$tmdb_title|$airdate_year"
        return
    fi

    echo "❌ Série non trouvée sur TMDb." >&2
    echo "Inconnu|Inconnu"
}

# Dictionnaire pour stocker les séries et éviter les doublons
declare -A series_map

# Lire tous les dossiers et les traiter
find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r folder_path; do
    folder=$(basename "$folder_path")
    ((total_folders++))

    # Exclure certains répertoires inutiles
    if [[ "$folder" =~ (dump|images|private|snippets|template) ]]; then
        echo "🚫 Ignorer : $folder_path (répertoire exclu)"
        continue
    fi

    echo "📂 Traitement du répertoire : $folder_path"

    # Extraction du nom et de l'année
    if [[ "$folder" =~ \(Recherche ]]; then
        series_name=$(echo "$folder" | sed -E 's/ \(Recherche.*//')
        current_year="Inconnu"
    elif [[ "$folder" =~ \(([0-9]{4})\)$ ]]; then
        series_name=$(echo "$folder" | sed -E 's/ \([0-9]{4}\)//')
        current_year="${BASH_REMATCH[1]}"
    else
        series_name="$folder"
        current_year="Inconnu"
    fi

    # Suppression des espaces en trop
    series_name=$(echo "$series_name" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    echo "📌 Nom extrait : $series_name"
    echo "📌 Année actuelle du répertoire : $current_year"

    # Récupérer le nom officiel et l'année depuis TMDb
    tmdb_data=$(get_tmdb_info "$series_name")
    tmdb_name=$(echo "$tmdb_data" | cut -d'|' -f1)
    tmdb_year=$(echo "$tmdb_data" | cut -d'|' -f2)

    echo "🔍 TMDb info récupérée : $tmdb_name ($tmdb_year)"

    if [[ "$tmdb_name" == "Inconnu" ]]; then
        echo "⚠️ Impossible de trouver '$series_name' sur TMDb. Vérification manuelle requise."
        manual_list+=("$folder")
        ((manual_check++))
        continue
    fi

    # Construire le nom de dossier correct
    new_folder_name="${tmdb_name} (${tmdb_year})"
    new_folder_path="$base_dir/$new_folder_name"

    echo "📝 Nouveau nom de dossier attendu : $new_folder_name"

    # Vérification avant renommage
    if [[ "$new_folder_name" != "$folder" ]]; then
        if [[ -d "$new_folder_path" ]]; then
            echo "⚠️  Dossier cible '$new_folder_name' existe déjà, fusion en cours."
            mv "$folder_path"/* "$new_folder_path" 2>/dev/null
            rmdir "$folder_path" 2>/dev/null && echo "🗑️ Dossier supprimé : $folder_path"
            ((merged_folders++))
        else
            echo "🚀 Renommage en cours : '$folder_path' -> '$new_folder_path'"
            mv "$folder_path" "$new_folder_path"
            ((renamed_folders++))
        fi
    fi

    # Vérification des doublons
    normalized_name=$(echo "$tmdb_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    if [[ -n "${series_map[$normalized_name]}" ]]; then
        target_folder="${series_map[$normalized_name]}"
        echo "🔄 Fusion de '$new_folder_name' -> '$target_folder'"
        mv "$new_folder_path"/* "$target_folder" 2>/dev/null
        rmdir "$new_folder_path" 2>/dev/null && echo "🗑️ Dossier supprimé : $new_folder_path"
        ((merged_folders++))
    else
        series_map[$normalized_name]="$new_folder_path"
    fi
done

# Affichage du rapport final
echo ""
echo "📊 RAPPORT FINAL :"
echo "------------------------"
echo "📂 Total des dossiers traités  : $total_folders"
echo "✍️  Dossiers renommés          : $renamed_folders"
echo "🔄 Dossiers fusionnés         : $merged_folders"
echo "⚠️  Dossiers à vérifier manuellement : $manual_check"

if [[ ${#manual_list[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 LISTE DES DOSSIERS À VÉRIFIER :"
    for folder in "${manual_list[@]}"; do
        echo "   - $folder"
    done
fi

echo "✅ Renommage terminé !"
