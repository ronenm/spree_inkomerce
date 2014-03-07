//= require admin/spree_backend

function inkomerce_show_hide_settings() {
    var $checkbox_field = $(this);
    if ($checkbox_field.prop('checked')) {
        $('.ink-button-show-hide').show('fast');
    } else {
        $('.ink-button-show-hide').hide('fast');
    }
    
}

$(document).ready(function() {
    var $checkbox = $('#product_ink_button_publish, #variant_ink_button_publish');
    if ($checkbox.length>0) {
        $checkbox.each(inkomerce_show_hide_settings);
        $checkbox.on('click', inkomerce_show_hide_settings);
    }
});

