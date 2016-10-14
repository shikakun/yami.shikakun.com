$(function() {
  var $button = $('.js-delete-brother');

  if (!$button.length) {
    return false;
  }

  $button.on('click', function() {
    if (window.confirm('Are you sure?')) {
      var $form   = $('<form>'),
          $input  = $('<input>');

      $form.attr({
        'action': '/admin/delete',
        'method': 'post'
      });

      $input.attr({
        'type'  : 'hidden',
        'name'  : 'id',
        'value' : $(this).attr('data-brother-id')
      });

      $form.append($input).submit().remove();
    }
  });
});
