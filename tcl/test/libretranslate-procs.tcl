ad_library {

    API Tests

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        libretranslate::detect
        libretranslate::translate
        libretranslate::translate_file
        libretranslate::suggest
    } \
    libretranslate_authenticated_api {
        Tests for API that requires an API Key. These won't be
        performed if no API has been configured.
    } {
        set server_url [string trimright [::parameter::get_global_value \
                                              -package_key libretranslate \
                                              -parameter ServerURL] /]
        set api_key [::parameter::get_global_value \
                         -package_key libretranslate \
                         -parameter APIKey]

        if {$server_url eq "" || $api_key eq ""} {
            aa_log "No server or API key configured. We skip this test."
            return
        }


        aa_section libretranslate::detect

        set r [::libretranslate::detect -text "The quick brown fox jumps over the lazy dog"]
        aa_equals "Language is detected" en [dict get $r language]
        aa_true "Confidence is a number" [string is double [dict get $r confidence]]


        aa_section libretranslate::translate

        aa_true "Translation looks sane" {[string first "volpe" $r] > -1}


        aa_section libretranslate::translate_file

        set wfd [ad_opentmpfile tmpnam .txt]
        puts $wfd "The quick brown fox jumps over the lazy dog"
        close $wfd

        set f [::libretranslate::translate_file -file $tmpnam -source_lang en -target_lang it]
        aa_true "File exists" [file exists $f]
        set rfd [open $f r]; set r [read $rfd]; close $rfd
        aa_true "Translation looks sane" {[string first "volpe" $r] > -1}


        aa_section libretranslate::suggest

        aa_false "Suggesting works" [catch {
            ::libretranslate::suggest \
                -text "Ciao, come ti chiami?" \
                -translation "Hello, what's your name?" \
                -source_lang it \
                -target_lang en
        }]
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        libretranslate::languages
        libretranslate::frontend
    } \
    libretranslate_unauthenticated_api {
        Tests for API that does not require an API Key.
    } {
        set server_url [string trimright [::parameter::get_global_value \
                                              -package_key libretranslate \
                                              -parameter ServerURL] /]
        aa_section libretranslate::languages

        set r [::libretranslate::languages]
        aa_true "Result is a list" {[llength $r] > 0}
        foreach k {code name targets} {
            aa_true "Result contains '$k' field" [dict exists [lindex $r 0] $k]
        }


        aa_section libretranslate::frontend

        set r [::libretranslate::frontend]
        foreach k {
            apiKeys
            charLimit
            filesTranslation
            frontendTimeout
            keyRequired
            language
            suggestions
            supportedFilesFormat
        } {
            aa_true "Result contains '$k' field" [dict exists $r $k]
        }

    }

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

