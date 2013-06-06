var CONTEST = {
  onReady : function() {
    $select = $( "#select-contest" );
    $select.on("change", function(event) {
      $select.find( "option:selected" ).each(function() {
        $this = $( this );
        
        if ($this.val() === "all") {
          $selected = $("tr:regex(class, contest-.*)");
          $selected.removeClass("hidden");
        } else {
          $selected = $("tr.contest-" + $this.val());
          $other = $("tr:regex(class, contest-(?!" + $this.val() + "))");
          $other.addClass("hidden");
          $selected.removeClass("hidden");
        }
      });
    })
  }
}

$( document ).ready(function() {

  CONTEST.onReady();
  
});
