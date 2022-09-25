#! /bin/zsh
ASSETS_DIR=$PWD/assets
RESPONSIVE_ASSETS_DIR=$ASSETS_DIR/img
# SIZES=(320 640 960 1280 1600)
SIZES=(560 655 874 1024 1230)


# converts the given file to webp if it is not already one.
convert_to_webp(){
    file=$1
    extension="${file##*.}"
    output_file="${file%.$extension}.webp"
    
    # converting to webp
    case $file in
        *.gif)
            gif2webp "$file" -o "$output_file"
        ;;
        *.jpeg|*.jpg|*.png)
            cwebp "$file" -o "$output_file"
        ;;
    esac
    
    echo "deleting $file"
    rm "$file"
    
    file=$output_file
    return 0
}

generate_responsive_images(){
    file=$1
    FILEWIDTH=$(identify -format "%w " "$file" | cut -d ' ' -f 1)
    FILENAME=$(basename -- "$file")
    FILESIZE=$(wc -c "$file" | xargs | cut -d ' ' -f 1)
    
    echo "file Width $FILEWIDTH, $FILENAME, $FILESIZE"
    
    for size in ${SIZES[@]}; do
        
        echo "optimizing for size $size"
        
        mkdir -p "$RESPONSIVE_ASSETS_DIR/$size"
        # if the destination file width exceeds the original file width, just copy the original file
        if [ "$size" -gt "$FILEWIDTH" ]; then
            echo "'$file' is smaller than $size px, copying it to '$RESPONSIVE_ASSETS_DIR/$size/'..."
            cp "$file" "$RESPONSIVE_ASSETS_DIR/$size/"
        else
            # compress the file
            echo "creating '$RESPONSIVE_ASSETS_DIR/$size/$FILENAME'"
            mogrify -path "$RESPONSIVE_ASSETS_DIR/$size" -define png:compression-level=9 -sampling-factor 4:2:0 -strip -quality 85 -interlace plane -colorspace sRGB -resize "$size"x "$file"
        fi
        
        FILE2="$RESPONSIVE_ASSETS_DIR/$size/$FILENAME"
        FILE2NAME=$(basename -- "$FILE2")
        FILE2SIZE=$(wc -c "$FILE2" | xargs | cut -d ' ' -f 1)
        
        if [[ "$FILE2NAME" == "$FILENAME" ]]; then
            # if the compressed file is bigger than the original file, overwrite it with the original file
            if [ "$FILE2SIZE" -gt "$FILESIZE" ]; then
                echo "'$FILE2' is bigger than '$file', copying '$file' to '$RESPONSIVE_ASSETS_DIR/$size'..."
                rm "$FILE2"
                cp "$file" "$RESPONSIVE_ASSETS_DIR/$size/"
            fi
        fi
    done
}

main(){
    echo "running image optimiser in $ASSETS_DIR"
    
    last_run_time='2022-01-01'
    if test -f "$LAST_RUN_TIME"; then
        echo "$LAST_RUN_TIME exists."
        last_run_time=$(head -n 1 filename)
    fi
    
    
    # iterate all files
    for file in $ASSETS_DIR/*
    do
        echo "\n"
        if [ ! -d "$file" ];
        then
            echo "processing file $file"
            extension="${file##*.}"
            
            case $extension in
                svg|webp)
                    echo "skipping svg/webp file"
                    continue
                ;;
                gif|jpeg|jpg|png)
                    # convert to webp
                    echo "converting image to webp"
                    convert_to_webp "$file"
                    
                    echo "$file is the output file "
                ;;
            esac
            
            # strip metadata from images
            convert $file -strip $file
            
            # generate responsive images
            generate_responsive_images $file
            
        else
            echo "$file is a folder, ignoring it and its contents"
        fi
    done
    
}

# start the script.
main