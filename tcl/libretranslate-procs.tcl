ad_library {

    Bindings to the LibreTranslate web API

    @see https://libretranslate.com/docs/

}

namespace eval libretranslate {}

ad_proc -public libretranslate::detect {
    -text:required
} {
    Detects language of provided text.

    @return a dict containing 'language' and 'confidence' fields.
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]
    set api_key [::parameter::get_global_value \
                     -package_key libretranslate \
                     -parameter APIKey]

    set r [::util::http::post \
               -url ${server_url}/detect \
               -formvars_list [list \
                                   q $text \
                                   api_key $api_key] \
              ]

    catch {package require json} errmsg

    if {[dict get $r status] == 200} {
        set content [::json::many-json2dict [dict get $r page]]
        return [lindex $content 0 0]
    } else {
        set content [::json::json2dict [dict get $r page]]
        error [list [dict get $r status] [dict get $content error]]
    }
}

ad_proc -public libretranslate::languages {} {
    Returns the list of supported languages.

    @return a list of dics containing for every language the fields
            'code', 'name' and 'targets' (the languages this can be
            translated into).
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]

    set r [::util::http::get -url ${server_url}/languages]

    if {[dict get $r status] == 200} {
        catch {package require json} errmsg
        return [::json::json2dict [dict get $r page]]
    } else {
        #
        # This API should never return an error. When it does, we
        # don't try to parse it and just hand it over to the user.
        #
        error [list [dict get $r status] [dict get $r page]]
    }
}

ad_proc -public libretranslate::frontend {} {
    Retrieves frontend configuration.

    @return frontend conf in dict format.
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]

    set r [::util::http::get -url ${server_url}/frontend/settings]

    if {[dict get $r status] == 200} {
        catch {package require json} errmsg
        return [::json::json2dict [dict get $r page]]
    } else {
        #
        # This API should never return an error. When it does, we
        # don't try to parse it and just hand it over to the user.
        #
        error [list [dict get $r status] [dict get $r page]]
    }
}

ad_proc -public libretranslate::translate {
    -text:required
    -source_lang:required
    -target_lang:required
    {-format text}
} {
    Translates text from one language to the other.

    @param format Format of the source text, either text or html.

    @return the translated text
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]
    set api_key [::parameter::get_global_value \
                     -package_key libretranslate \
                     -parameter APIKey]

    set r [::util::http::post \
               -url ${server_url}/translate \
               -formvars_list [list \
                                   q $text \
                                   source $source_lang \
                                   target $target_lang \
                                   format $format \
                                   api_key $api_key] \
              ]

    catch {package require json} errmsg
    set content [::json::json2dict [dict get $r page]]

    if {[dict get $r status] == 200} {
        return [dict get $content translatedText]
    } else {
        error [list [dict get $r status] [dict get $content error]]
    }
}

ad_proc -public libretranslate::translate_file {
    -file:required
    -source_lang:required
    -target_lang:required
} {
    Translates text from one language to the other.

    @param file absolute path to a file to be translated.

    @return absolute path to the translated file
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]
    set api_key [::parameter::get_global_value \
                     -package_key libretranslate \
                     -parameter APIKey]

    set r [::util::http::post \
               -url ${server_url}/translate_file \
               -files [list [list \
                                 file $file \
                                 fieldname file]] \
               -formvars_list [list \
                                   source $source_lang \
                                   target $target_lang \
                                   api_key $api_key] \
              ]

    catch {package require json} errmsg
    set content [::json::json2dict [dict get $r page]]

    if {[dict get $r status] == 200} {
        #
        # Response should contain the URL to the translated result. We
        # go fetch it.
        #
        set translated_file_url [dict get $content translatedFileUrl]
        set r [util::http::get -url $translated_file_url -spool]
        if {[dict get $r status] == 200} {
            return [dict get $r file]
        } else {
            #
            # Downloading the translated file failed. This is not
            # covered by the API spec.
            #
            error [list [dict get $r status] [dict get $r page]]
        }
    } else {
        error [list [dict get $r status] [dict get $content error]]
    }
}

ad_proc -public libretranslate::suggest {
    -text:required
    -translation:required
    -source_lang:required
    -target_lang:required
} {
    Sends a suggestion to improve a translation to the backend.

    @return nothing, or an error in case of failure.
} {
    set server_url [string trimright [::parameter::get_global_value \
                                          -package_key libretranslate \
                                          -parameter ServerURL] /]

    set api_key [::parameter::get_global_value \
                     -package_key libretranslate \
                     -parameter APIKey]

    set r [::util::http::post \
               -url ${server_url}/suggest \
               -formvars_list [list \
                                   q $text \
                                   s $translation \
                                   source $source_lang \
                                   target $target_lang \
                                   api_key $api_key] \
              ]

    if {[dict get $r status] != 200} {
        catch {package require json} errmsg
        set content [::json::json2dict [dict get $r page]]
        error [list [dict get $r status] [dict get $content error]]
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
