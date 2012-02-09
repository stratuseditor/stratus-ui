###
Validation forms.

  validate $("input[name='password']"), ($el, callback) ->
    errors = []
    errors.push "Password is a required field" if !$el.val()
    return callback errors
  
  validate.form $form,
    selector: ($el, callblack) ->
    selector: ($el, callblack) ->
    selector: ($el, callblack) ->

###

CSS_CLASSES =
  SUCCESS: "success"
  FAILURE: "failure"
  LOADING: "loading"

# Validate a form field.
# 
# $input - An input element.
# valid  - A function which receives the input element and a callback
#          to which should be passed an array of errors.
# 
# Examples
# 
#   validate $("input"), ($el, callback) ->
#     val    = $el.val()
#     errors = if val then [] else "Username is required."
#     return callback errors
# 
validate = ($input, valid) ->
  new Validation $input, valid

# Validate a form.
# 
# $form       - a jQuery element: either a form or an input.
# validations - A hash where the keys are selectors of form inputs, and
#               the values are functions. Each function receives
#               ($el, callback). The callback should be passed an array
#               of errors on the field, or a single string error.
# 
# Examples
# 
#   validate.form $("form"),
#     "[name='username']": ($el, callback) ->
#       val    = $el.val()
#       errors = if val then [] else "Username is required."
#       return callback errors
#     
#     "[name='password']": ($el, callback) ->
#       val    = $el.val()
#       errors = []
#       if val.length <= 4
#         errors.push "Your password is too weak."
#       if val == "123456"
#         errors.push "That is the dumbest password ever."
#       if val == "hellokitty"
#         errors.push "Your password is way too immature."
#       return callback errors
# 
validate.form = ($form, validations) ->
  vs = []
  
  for selector, valid of validations
    vs.push new Validation $form.find(selector), valid
  
  $form.submit (event) ->
    fail = _.once ->
      event.preventDefault()
    
    for validation in vs
      switch validation.state
        when "failure"
          fail()
        when null
          fail()
          validation.check (success) ->
            $form.submit() if success
  


class Validation
  constructor: (@$el, @valid) ->
    @state    = null
    @$p       = @$el.parent()
    @$p.append @$icon = "<span class='icon'></span>"
    
    @$el.blur =>
      @check()
  
  # Public:
  # Validate. The optional callback receives a boolean success parameter.
  check: (callback) ->
    @loading()
    @valid @$el, (errors) =>
      errors ?= []
      errors  = [errors] if typeof(errors) == "string"
      # There are some errors to handle...
      if errors.length
        callback? false
        @failure()
        @setErrors errors
      # Success!
      else
        callback? true
        @success()
        @clearErrors()
  
  # Show a spinner. Usually displayed when the server is being queried,
  # for example while checking if a username is taken.
  loading: ->
    @state = "loading"
    @_arr @$p,
      CSS_CLASSES.LOADING,
      CSS_CLASSES.FAILURE,
      CSS_CLASSES.SUCCESS
  
  # All validations passing.
  success: ->
    @state = "success"
    @_arr @$p,
      CSS_CLASSES.SUCCESS,
      CSS_CLASSES.FAILURE,
      CSS_CLASSES.LOADING
  
  # One or more errors prevent passing.
  failure: ->
    @state = "failure"
    @_arr @$p,
      CSS_CLASSES.FAILURE,
      CSS_CLASSES.SUCCESS,
      CSS_CLASSES.LOADING
  
  # Update the UI to display the given errors.
  # 
  # errors - an array of error strings to be displayed.
  # 
  setErrors: (errors) ->
    @$p.children("ul.errors").remove()
    $input  = @$p.find("input")
    $errors = $ "<ul class='errors'>
      <li>#{ errors.join("</li><li>") }</li>
    </ul>"
    @$p.append $errors
    top = $input.position().top +
          $input.outerHeight(true) -
          +$input.css("margin-bottom").replace(/px/, "")
    $errors.css {top}
  
  # Hide the errors being displayed.
  clearErrors: ->
    @$p.children("ul").slideUp "fast", ->
      $(this).remove()
  
  # Add Remove Remove class.
  _arr: ($el, a, r1, r2) ->
    $el.addClass(a).removeClass "#{ r1 } #{ r2 }"


module.exports = validate
