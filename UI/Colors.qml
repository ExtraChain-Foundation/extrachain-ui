pragma Singleton

import QtQuick
/**
    all colors must be in upper case
*/

QtObject {
    property bool isDarkTheme: true
    property string logo_and_text: Colors.isDarkTheme ? "qrc:/new_design/UI/Images/new_design/raccoon_logo_and_text.png"
                                                      : "qrc:/new_design/UI/Images/new_design/raccoon_logo_and_text_wt.png"

    property color background: isDarkTheme ? "#191A1A" : "#E7E8EC"
    property color background_start: isDarkTheme ? "#10191A1A" : "#10E7E8EC"
    property color background_end: isDarkTheme ? "#20191A1A" : "#30E7E8EC"
    property color background_old: isDarkTheme ? "#081420" : "#F5F5F6"
    property color selector_menu: isDarkTheme ? "#191A1A" : "#FFFFFF"
    property color raccoon_icon: isDarkTheme ? "#FFFFFF" : "#000000"
    property color mining_background: isDarkTheme ? "#191A1A" : background
    property color mining_text_color: "#70C8FF"
    property color border_color: isDarkTheme ? "#1069839a" : "white"
    property color inactive_mining_text_color: "#555556"
    property color mobile_notification_settings_box: isDarkTheme ? "#181C33" : "#B5BFC6"
    property color mobile_notification_settings_text: isDarkTheme ? "#FFFFFF" : "#191A1A"
    property color location_background: isDarkTheme ? "#191A1A" : background
    property color location_select_color: isDarkTheme ? "#FFFFFF" : "#191A1A"
    property color location_additional_color: isDarkTheme ? "#FFFFFF" : "#D3D2D8"
    property color connect_zone: isDarkTheme ? "#3D3B4D" : "#D3D2D8"
    property color def_color_text: isDarkTheme ? "#FFFFFF" : "#4A5564"
    property color detault_text_color: isDarkTheme ? "#FFFFFF" : "#4A5564"
    property color grape_gray_color: isDarkTheme ? "#C3C3C3" : def_color_text
    property color message_window_text: "#ED6372"
    property color top_header: "#99FFFFFF"
    property string connect_zone_old: isDarkTheme ? "#071B30" : "#FFFFFF"
    property color red: "#D95458"
    property color green: isDarkTheme ? "#42FFA0" : "#086623"
    property color deep_indigo_text_color: "#FFFFFF"
    property string default_shadow: isDarkTheme ? "#80ffffff" : "#80000000"

    property QtObject popup: QtObject {
        property color gradient_begin: "#1F2121"
        property color gradient_end: "#292E2D"
        property color border: "#292E2D"
    }

    property QtObject raccoon_page: QtObject {
        property color gradient_begin: "#01191A1A"
        property color gradient_end: "#07314D"
    }

    property QtObject menu_selector: QtObject {
        property color background: isDarkTheme ? "#121212" : "#F5F5F5"
        property color border_color: "#c5c5c5"
    }

    property QtObject text_field_style: QtObject{
        property string placeholder: isDarkTheme ? "#FFFFFF" : "#555556"
        property string background: isDarkTheme ? "#333333" : "#E7E8EC"
        property string border_color: "#333333"
    }

    property QtObject country_list: QtObject {
        property string country_name_description: "#70C8FF"
        property string country_name: isDarkTheme ? "#FFFFFF" : "#191A1A"
    }

    property QtObject country_list_old: QtObject {
        property string country_name_description: isDarkTheme ? "#6C727A" : "#575757"
        property string country_name: isDarkTheme ? "#FFFFFF" : "#4A5564"
    }

    property QtObject wallet_withdraw_page: QtObject {
        property color background: isDarkTheme ? "#081420" : "#F5F5F6"
        property color background_list_view: isDarkTheme ? "#1B2631" : "#FFFFFF"
        property color box_active_color: isDarkTheme ? "#043567" : "#BEE0F5"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color tx_text: isDarkTheme ? "#9CA4AC" : "#575757"
        property color tx_coin_and_value: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color uncheckBackground: isDarkTheme ? "#333D46" : "#E9E9E9"

        property QtObject button_back_style: QtObject {
            property color pressed_color_icon: isDarkTheme ? "#FFFFFF" : "#090909"
            property color color_icon: isDarkTheme ? "#F5F5F6" : "#B5B5B5"
            property color selected_background: isDarkTheme ? "#081420" : "#F5F5F6"
        }
    }

    property QtObject withdraw: QtObject {
        property color wallet_list_background: isDarkTheme ? "#333333": "#E7E8EC"
        property color text: !def_color_text
        property color enabled_button:  isDarkTheme ? "#9A9A9A" :"#BFBFBF"
        property color disabled_button: "#828385"
    }

    property QtObject status_create_wallet: QtObject {
        property color check: "#4ACE9F"
        property color text: "#3891D5"
    }

    property QtObject raccoonComboBoxDefaultStyle: QtObject {
        property color background: isDarkTheme ? "#191A1A" : "#E7E8EC"
        property color selected_text: isDarkTheme ? "#908E98" : "#090909"
        property color border: "#3C394E"
    }

    property QtObject raccoonTextFieldDefaultStyle: QtObject {
        property color max_button: isDarkTheme ? "#FFFFFF" : "#090909"
        property color name_coin:  isDarkTheme ? "#A4A8AD" : "#757575"
        property color error_border_color: "#FF0000"
        property color border_color: isDarkTheme ? "#A4A8AD" : "#1B2631"
    }

    property QtObject loaderBlochain: QtObject {
        property color background: isDarkTheme ? "#071B30" : "#B5B5B5"
        property color text: isDarkTheme ? "#FFFFFF" : "#090909"
    }

    property QtObject createWalletPage: QtObject {
        property color title_text: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color text: isDarkTheme ? "#60FFFFFF" : "#575757"
        property color separator: isDarkTheme ? "#10FFFFFF" : "#05090909"
    }

    property QtObject button_deposit_style: QtObject {
        property string background: "#3891D5"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#090909"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject button_blue_style: QtObject {
        property string background: isDarkTheme ? "#043567" : "#D0E8F5"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#090909"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject button_square_default_style: QtObject {
        property string pressed_color_icon: isDarkTheme ? "#FFFFFF" : "#090909"
        property string color_icon: isDarkTheme ? "#6B7683" : "#B5B5B5"
        property string selected_background: isDarkTheme ? "#081420" : "#F5F5F6"
    }

    property QtObject button_menu_square_default_style: QtObject {
        property string pressed_color_icon: "#70C8FF"
        property string color_icon: "#70C8FF"
        property string selected_background: isDarkTheme ? "#081420" : "#F5F5F6"
    }

    property QtObject disconnected_indicator: QtObject {
        property string outside: isDarkTheme ? "#785362" : "#F8C1C7"
        property string inside: "#ED6372"
        property string text_color: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property string location_text_color: isDarkTheme ? "#9CA4AC" : "#848484"
    }

    property QtObject in_process_indicator: QtObject {
        property string outside: "#FFA700"
        property string inside: "#EEE600"
    }

    property QtObject connected_indicator: QtObject {
        property string outside: isDarkTheme ? "#22635C" : "#B7EBD3"
        property string inside: "#4BCF90"
        property string text_color: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property string location_text_color: isDarkTheme ? "#9CA4AC" : "#848484"
    }

    property QtObject button_withdrawal_style_old: QtObject {
        property string background: "transparent"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#090909"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject wallet_page_old: QtObject {
        property color color_text: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color header_color: isDarkTheme ? "#CFD2D4" : "#575757"
        property color separator: isDarkTheme ? "#22333E" : "#EFEFF0"
        property color background: isDarkTheme ? "#0B1C2A" : "#FBFBFB"
        property color name_short_coin: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color name_coin: isDarkTheme ? "#9DA5AA" : "#757575"
        property color coin_price_and_balance: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color value: isDarkTheme ? "#9DA5AA" : "#757575"
        property color background_menu: isDarkTheme ? "#071B30" : "#FFFFFF"

        function pnlText(pnl) {
            if (pnl >= 0)
                return "<font color=\"#4ACE9F\">+"+pnl+"%</font>"
            else
                return "<font color=\"#ED6372\">-"+pnl+"%</font>"
        }
    }

    property QtObject button_deposit_style_old: QtObject {
        property string background: "#3891D5"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#090909"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject wallet_menu_style_old: QtObject {
        property string background: isDarkTheme ? "#081420" : "#F5F5F6"
        property color color_text: isDarkTheme ? "#FFFFFF" : "#090909"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject menuPopup_old: QtObject {
        property color background: isDarkTheme ? "#071B30" : "#D0E8F5"
        property color text: isDarkTheme ? "#FFFFFF" : "#090909"
        property color border: "#575757"
    }

    property QtObject menuPopup: QtObject {
        property color background: mobile_notification_settings_box
        property color text: def_color_text
        property color border: Colors.mining_text_color
    }

    property QtObject dfs_page: QtObject {
        property color storage_used_background_indicator: isDarkTheme ? "#535B63" : "#C3C3C3"
        property color storage_used_fill_background_indicator: isDarkTheme ? "#3FAFF1" : "#3FAFF1"
        property color folder: isDarkTheme ? "#0D2436" : "#EFEFF0"
        property color folder_user: isDarkTheme ? "#800D2436" : "#80EFEFF0"
        property color folder_text: isDarkTheme ? "#FFFFFF" : "#575757"
        property color title: isDarkTheme ? "#FFFFFF" : "#4A5564"
        property color space_info_gradient_begin: "#70C8FF"
        property color space_info_gradient_end: "#3891D5"
        property color upgrade_button_gradient_begin: "#70C8FF"
        property color upgrade_button_gradient_end: "#0052B4"
        property color onboarding_file: isDarkTheme ? "#1D2239" : "#DBDBDB"
        property color file_size: "#9E9DA6"
        property color onboarding_date_time: "#6E6E7B"
        property color onboarding_box_color: "#767A9A"
        property color drop_indicator_background: "#3891D5"
        property color drop_indicator_text: "#FFFFFF"
        property color image_container: isDarkTheme ? "#2E2E2E" : "#939BA0"
        property color created: "#6E6E7B"
        property color file_infobox_background: "#1C1E35"
        property color file_infobox_text: "#3891D5"
        property color search_placeholder: "#8C8A96"
        property color search_border_color: "#211F33"
        property color column_menu_list_pressed: isDarkTheme ? "#05121212" : "#05F2F3F7"
        property color column_menu_list_unpressed: isDarkTheme ? "#121212" : "#F2F3F7"
        property color selected: isDarkTheme ? "#333333" : "#A3ACB2"
        property string storage_text: isDarkTheme ? "<font color=\"#FFFFFF\">Storage</font><font color=\"#9CA1A6\"> 00.00 GB for 15 GB used</font>"
                                                 : "<font color=\"#4A5564\">Storage</font><font color=\"#575757\"> 00.00 GB for 15 GB used</font>"

        function storage_calc_text(size, max) {
            if (isDarkTheme) {
                return "<font color=\"#FFFFFF\">" +size+ " GB</font><font color=\"#FFFFFF\"> used of " +max+ " GB</font>"
            } else {
                return "<font color=\"#252827\">" +size+ " GB</font><font color=\"#252827\"> used of " +max+ " GB</font>"

            }
        }
    }

    property QtObject button_lightblue_style_old: QtObject {
        property string background: "#287EC7"
        property color color_text: "#FFFFFF"
        property int radius: 16
        property real opacity_pressed: 0.7
    }

    property QtObject settings_page: QtObject {
        property color text: isDarkTheme ? "#FFFFFF" : "#090909"
        property string settings_panel_color: isDarkTheme ? "#0E1D35" : "#C3C3C3"
        property color separate_color: "#333743"
        property color background: isDarkTheme ? "#121212" : "#E7E8EC"
        property color border_color: "#283B59"
        property color icon: "#70C8FF"
    }

    property QtObject subscriptionPage: QtObject {
        property color text: isDarkTheme ? "#FFFFFF" : "#090909"
    }

    property QtObject messenger: QtObject {
        property color background_receiver: isDarkTheme ? "#425e7b" : "#2b3b5b"
        property color background_sender: isDarkTheme ? "#505a71" : "#5e5e5e"
        property color day_separator: "#2F3C4E"
        property color day_separator_text: "#B0BAC6"
        property color scroll_bar: "#98a2af"
        property color menu_add_background: "#2f4156"
        property color selection_color: "#3399ff88"

        property QtObject file_delegate: QtObject {
            property color icon:"#3891D5"
        }

        property QtObject image_delegate: QtObject {
            property color background:"#98a2af"
        }

        property QtObject menu: QtObject {
            property color background:"#2f4156"
        }

        property QtObject choose_delegate: QtObject {
            property color me:"#DCF8C6"
            property color not_me:"#ffffff"
        }

        property QtObject text_delegate: QtObject {
            property color selection_color:"#3399ff88"
        }

        property QtObject video_delegate: QtObject {
            property color icon:"#3891D5"
        }
    }

    property QtObject checkBox: QtObject {
        property color text: def_color_text
        property color checked: isDarkTheme ? "#5F6675" : "#FFFFFF"
        property color unchecked: isDarkTheme ? "#5F6675" : "#FFFFFF"
        property color border: "#333333"
    }

    property QtObject button_square_send_message_style: QtObject {
        property string pressed_color_icon: isDarkTheme ? "#FFFFFF" : "#090909"
        property string color_icon: isDarkTheme ? "#425e7b" : "#2b3b5b"
        property string selected_background: isDarkTheme ? "#081420" : "#F5F5F6"
    }

    property QtObject notificationPopup: QtObject {
        property color background: isDarkTheme ? "#121212" : "#EAEBEF"
        property color icon_placeholder: isDarkTheme ? "#191A1A" : "#D9E3E5"
        property color text: def_color_text
        property color description: grape_gray_color
        property color border: "#3E3F3E"
    }

    property QtObject wallet: QtObject {
        property color select_wallet_background_button: isDarkTheme ? "#23283E" : "#D3D2D8"
        property color select_wallet_button: isDarkTheme ? "#FFFFFF" : "#23283E"
        property color rename_wallet_background: isDarkTheme ? "#1C1F35" : "#F2F3F7"
        property color background: isDarkTheme ? "#121212" : "#F2F3F7"
        property color shadow: isDarkTheme ? "#191A1A" : "#E7E8EC"
        property color shadow_60p: isDarkTheme ? "#60191A1A" : "#60E7E8EC"
        property color shadow_20p: isDarkTheme ? "#20191A1A" : "#20E7E8EC"
        property color choose_wallet_background: isDarkTheme ? "#181C33" : "#D9E3E5"
        property color selected_wallet: isDarkTheme ? "#181C33" : "#CDD7D9"
        property color not_selected_wallet: isDarkTheme ? "#121329" : "#D7DFE1"
    }

    property QtObject subscription: QtObject {
        property color title_color_available: "#FFBF1C"
        property color title_color_unavailable: "#70C8FF"
        property color switch_background: isDarkTheme ? "#161F36" : "#BEBEBE"
        property color selected_annual_plan: isDarkTheme ? "#42536A" : "#DCDAD9"
        property color unselected_annual_plan:  isDarkTheme ? "#161F36" : "#BEBEBE"
        property color selected_annual_plan_text: "#161F36"
        property color unselected_annual_plan_text: "#868995"
        property color monthly_background:isDarkTheme ? "#42536A" : "#DCDAD9"
        property color monthly_background_unselected: switch_background
        property color monthly_text: "#161F36"
        property color monthly_text_unselected: "#161F36"
        property color plan_card_gradient_begin: "#FFBF1C"
        property color plan_card_gradient_end: "#535314"
        property color plan_card_unavailable_background: isDarkTheme ? "#100F24" : "#EEEEEE"
        property color plan_card_available_background: isDarkTheme ? "#15172E" : "#EEEEEE"
        property color plan_card_title_available: "#FFBF1C"
        property color plan_card_title_unavailable: "#253956"
        property color title_box_unavailable: "#253956"
        property color title_box_available: "#44392A"
        property color text: isDarkTheme ? "#B9C5D1" : grape_gray_color
        property color activated_text: "#191A1A"
        property color unavailable_text: "#83828E"
        property color placeholder_icon: isDarkTheme ? "#171B32" : "#B5BFC6"
        property color back_color: isDarkTheme ? "#ABADB5" : grape_gray_color
    }

    property QtObject blue_button: QtObject {
        property color filled_color: "#70C8FF"
        property color filled_text_color: "#191A1A"
        property color disabled_text_color: grape_gray_color
    }

    property QtObject deep_indigo_button: QtObject {
        property color begin_gradient_color: isDarkTheme ? "#1F1C31" : "#9B9B9B"
        property color end_gradient_color: isDarkTheme ? "#213A58" : "#B6B6B6"
    }


    property QtObject switch_control: QtObject {
        property color indicator_color: Colors.isDarkTheme ? "#1B2D42" : "#DBDBDB"
        property color handled: "#3FAFF1"
        property color unhandled: "#5F6C7A"
    }

    property QtObject message_box: QtObject {
        property color background: "#2A3135"
    }

    property QtObject vpn_sphere: QtObject {
        property color blue: "#70C8FF"
        property color sky_blue:"#4A90E2"
    }

    property QtObject vpn: QtObject {
        property color status_disconnected: "#ED6372"
        property color status_connecting: "#F0B503"
        property color status_connected: "#70C8FF"
        property color popup_gradient_begin: "#70C8FF"
        property color popup_gradient_end: Colors.isDarkTheme ? "#143053" : "#E3F4FF"

    }

    property QtObject onboarding: QtObject {
        property color close_button_pressed_color: "#69839A"
        property color title: "#70C8FF"
        property color description: isDarkTheme ? "#C4C5CA" : grape_gray_color
        property color step_text: isDarkTheme ? "#8B8D98" : grape_gray_color
        property color background: "#767A9A"
        property color border: isDarkTheme ? "transparent" : "#C4C5CA"
    }

    property QtObject quality_signal: QtObject {
        property color good_quality: "#F0B503"
        property color bad_quality: "#FF0D00"
        property color excelent_quality_begin: "#83FFC1"
        property color excelent_quality_end: "#00FF7F"
        property color signal_color: "#69839A"
    }

    property QtObject image_preview: QtObject {
        property color background: "#0d0d0d"
        property color menu: "#2f4156"
    }

    property QtObject deposit: QtObject {
        property color background: isDarkTheme ? "#121212" : "#F5F5F6"
        property color enabled: isDarkTheme ? "#9A9A9A" :"#BFBFBF"
        property color disabled: "#3D658B"
        property color text: isDarkTheme ? "#F5F5F6" : "#121212"
    }

    property QtObject export_page: QtObject {
        property color background: "#0D0A21"
        property color text: "#5e5e5e"
    }

    property QtObject login_page: QtObject {
        property color mnemonic_background: "#0D0A21"
    }

    property QtObject notification: QtObject {
        property color border_color: "#283B59"
        property color icon: "#807E8A"
        property color selected: isDarkTheme ? "#333333" : "#D1D6E0"
        property color unselected: isDarkTheme ? "#232323" : "#10B5BFC6"
        property color placeholder_icon_selected: isDarkTheme ? "#333333" : "#D9E3E5"
        property color placeholder_icon_unselected: isDarkTheme ? "#333333" : "#D9E3E5"
        property color amount_selected: "#667085"
        property color amount_unselected: "#A8A7AF"
        property color time: "#807E8A"
        property color detail_placeholder_icon: isDarkTheme ? "#181C33" : "#D9E3E5"
        property color detail_placeholder_border_color: "#232A41"
    }
}
