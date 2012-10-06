function error(msg) {
    $('#status .success').hide();
    $('#status .failure').text(msg).show();
}

function success(msg) {
    $('#status .failure').hide();
    $('#status .success').text(msg).show();
}

function validateAmount() {
    var amt_str = $('#amount input')[0].value.trim();
    if (amt_str.length == 0) {
        return error("You must specify an amount.");
    }
    var match = /^(\d+)(?:\.(\d{2}))?$/.exec(amt_str);
    if (!match) {
        return error("Invalid amount: "+ amt_str);
    }
    var cents = parseInt(match[2] || "0");
    // It's kinda cute how I'm trying to only use integer arithmetic
    // here,
    // even though Javascript is storing everything as floats
    // internally...
    return parseInt(match[1]) * 100 + cents;
}

function formatAmount(amt) {
    var cents = "" + (amt%100);
    while (cents.length < 2) cents = "0" + cents;
    return "$" + (Math.floor(amt/100)) + "." + cents;
}

function doPayment(e, token) {
    var amt = validateAmount();
    if (amt == null) return;
    $.post('/money/ajax/pay',
          { amount: amt, token: token.id },
          function () {
              success("Successfully charged " + formatAmount(amt) + " -- Thank you!");
          }).fail(
          function(xhr, status) {
              var err;
              try {
                  err = JSON.parse(xhr.responseText).error;
              } catch (x) {
                  err = "Unknown error"
              }
              error("Payment failed: " + err);
          });
}

$(function() {
    $('.stripe-button').bind('token', doPayment);
    $('.stripe-button-inner').click(function() {
            return !!validateAmount();
    });
});
