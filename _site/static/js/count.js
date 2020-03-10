$(document).ready(function() {
    pre_content = $("#son_site_pv").html();
    $("#son_site_pv").html(pre_content);
    $.ajax({
        type: "get",
        async: false,
        url: "https://miniapp.jack003.com/counter.cgi",
        dataType: "jsonp",
        jsonp: "callback",
        jsonpCallback: "flightHandler",
        success: function(json) {
            var website_count = json.data;
            $("#son_site_pv").html('<span class="navy">' + website_count + '</span>&nbsp;<span data-i18n="link.view">views</span>&nbsp;||&nbsp;' + pre_content);
        },
        error: function() {
            console.log('fail');
        }
    });
});
