#!/bin/bash

if [ "$1" = "outputs" ]; then
    pw-dump | jq '.[] 
    | select(.type == "PipeWire:Interface:Node") 
    | select(.info.props."media.class" == "Stream/Output/Audio") 
    | {id: .id, client_id: .info.props."client.id", media_class: .info.props."media.class", name: .info.props."node.name", description: .info.props."node.description", positions: ."info"."params"."PortConfig"[]?."format"."position" | join(" ")}'
fi

if [ "$1" = "inputs" ]; then
    pw-dump | jq '.[] 
    | select(.type == "PipeWire:Interface:Node") 
    | select(.info.props."media.class" == "Stream/Input/Audio") 
    | {id: .id, client_id: .info.props."client.id", media_class: .info.props."media.class", name: .info.props."node.name", description: .info.props."node.description", positions: ."info"."params"."PortConfig"[]?."format"."position" | join(" ")}'
fi

         #arg           output_name    input_name     output_pos_list input_pos_list
         #link          spotify        Sober          "FL FR"         "MONO"
         #&& [ -z "$2" ] && [ -z "$3" ] && [ -z "$4" ] && [ -z "$5" ]; #this doesn't work, stack overflow lied to me
if [ "$1" = "link" ]; then
    IFS=' ' read -r -a output_pos <<< "$4"
    IFS=' ' read -r -a input_pos <<< "$5"

    if [ ${#input_pos[@]} = 1 ]; then
        for outpos in "${output_pos[@]}"
        do
            output="${2}:output_${outpos}"
            input="${3}:input_${input_pos[0]}"
            pw-link $output $input
        done
        exit 0
    fi

    #only does matches because idk how else to handle something like this
    if [ ${#input_pos[@]} > 1 ] && [ ${#output_pos[@]} > 1 ]; then

        for outpos in "${output_pos[@]}"
        do
            for inpos in "${input_pos[@]}"
            do
                if [ $outpos = $inpos ]; then
                    output="${2}:output_${outpos}"
                    input="${3}:input_${inpos}"
                    pw-link $output $input
                fi
            done
        done
        exit 0
    fi

    if [ ${#output_pos[@]} = 1 ]; then
        for inpos in "${input_pos[@]}"
        do
            output="${2}:output_${output_pos[0]}"
            input="${3}:input_${inpos}"
            pw-link $output $input
        done
        exit 0
    fi

fi


#arg           output_name    input_name     output_pos_list input_pos_list
#unlink        spotify        Sober          "FL FR"         "MONO"
if [ "$1" = "unlink" ]; then # same as above but with 
    IFS=' ' read -r -a output_pos <<< "$4"
    IFS=' ' read -r -a input_pos <<< "$5"

    if [ ${#input_pos[@]} = 1 ]; then
        for outpos in "${output_pos[@]}"
        do
            output="${2}:output_${outpos}"
            input="${3}:input_${input_pos[0]}"
            pw-link -d $output $input || true
        done
        exit 0
    fi

    #only does matches because idk how else to handle something like this
    if [ ${#input_pos[@]} > 1 ] && [ ${#output_pos[@]} > 1 ]; then

        for outpos in "${output_pos[@]}"
        do
            for inpos in "${input_pos[@]}"
            do
                if [ $outpos = $inpos ]; then
                    output="${2}:output_${outpos}"
                    input="${3}:input_${inpos}"
                    pw-link -d $output $input || true
                fi
            done
        done
        exit 0
    fi

    if [ ${#output_pos[@]} = 1 ]; then
        for inpos in "${input_pos[@]}"
        do
            output="${2}:output_${output_pos[0]}"
            input="${3}:input_${inpos}"
            pw-link -d $output $input || true
        done
        exit 0
    fi
fi

#arg              output_name    input_name     output_pos_list input_pos_list
#checklink        spotify        Sober          "FL FR"         "MONO"
if [ "$1" = "checklink" ]; then #basic link checking until I make it better for multiple positions in out and in

    #thank you chatgpt for this even though it took 20 mins to guide you
    #pw-link -l | awk '/^spotify:output_FL$/ {f=1; next} /^[^[:space:]]/ {f=0} f && /Sober:input_MONO/ {print "true"; exit} END{if(NR && !f) print "false"}'
    
    IFS=' ' read -r -a output_pos <<< "$4"
    IFS=' ' read -r -a input_pos <<< "$5"

    if [ ${#input_pos[@]} = 1 ]; then
        for outpos in "${output_pos[@]}"
        do
            output="${2}:output_${outpos}"
            input="${3}:input_${input_pos[0]}"
            result=$(pw-link -l | awk -v output="$output" -v input="$input" '$0 == output {f=1; next} /^[^[:space:]]/ {f=0} f && $0 ~ input {print "true"; exit} END{if(NR && !f) print "false"}')
            if [ $result = "false" ]; then
                echo "link missing ${output} > ${input}"
                exit 1
            fi
        done
        exit 0
    fi

    #only does matches because idk how else to handle something like this
    if [ ${#input_pos[@]} > 1 ] && [ ${#output_pos[@]} > 1 ]; then

        for outpos in "${output_pos[@]}"
        do
            for inpos in "${input_pos[@]}"
            do
                if [ $outpos = $inpos ]; then
                    output="${2}:output_${outpos}"
                    input="${3}:input_${inpos}"
                    result=$(pw-link -l | awk -v output="$output" -v input="$input" '$0 == output {f=1; next} /^[^[:space:]]/ {f=0} f && $0 ~ input {print "true"; exit} END{if(NR && !f) print "false"}')
                    if [ $result = "false" ]; then
                        echo "link missing ${output} > ${input}"
                        exit 1
                    fi
                fi
            done
        done
        exit 0
    fi

    if [ ${#output_pos[@]} = 1 ]; then
        for inpos in "${input_pos[@]}"
        do
            output="${2}:output_${output_pos[0]}"
            input="${3}:input_${inpos}"
            result=$(pw-link -l | awk -v output="$output" -v input="$input" '$0 == output {f=1; next} /^[^[:space:]]/ {f=0} f && $0 ~ input {print "true"; exit} END{if(NR && !f) print "false"}')
            if [ $result = "false" ]; then
                echo "link missing ${output} > ${input}"
                exit 1
            fi
        done
        exit 0
    fi


fi