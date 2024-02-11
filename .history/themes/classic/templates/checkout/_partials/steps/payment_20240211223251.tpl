{extends file='checkout/_partials/steps/checkout-step.tpl'}

{block name='step_content'}

  {hook h='displayPaymentTop'}

  <div class="form-group">
    <label for="slipFile" class="col-sm-3 col-form-label">{l s='เลือกไฟล์สลิป:' d='Shop.Theme.Actions'}</label><br>
    <input type="file" class="form-control-file" id="slipFile" name="slipFile" accept=".png, .jpg" required>
  </div>
  
  {* used by javascript to correctly handle cart updates when we are on payment step (eg vouchers added) *}
  <div style="display:none" class="js-cart-payment-step-refresh"></div>

  {if !empty($display_transaction_updated_info)}
  <p class="cart-payment-step-refreshed-info">
    {l s='Transaction amount has been correctly updated' d='Shop.Theme.Checkout'}
  </p>
  {/if}

  {if $is_free}
    <p class="cart-payment-step-not-needed-info">{l s='No payment needed for this order' d='Shop.Theme.Checkout'}</p>
  {/if}
  <div class="payment-options {if $is_free}hidden-xs-up{/if}">
    {foreach from=$payment_options item="module_options"}
      {foreach from=$module_options item="option"}
        <div>
          <div id="{$option.id}-container" class="payment-option clearfix">
            {* This is the way an option should be selected when Javascript is enabled *}
            <span class="custom-radio float-xs-left">
              <input
                class="ps-shown-by-js {if $option.binary} binary {/if}"
                id="{$option.id}"
                data-module-name="{$option.module_name}"
                name="payment-option"
                type="radio"
                required
                {if ($selected_payment_option == $option.id || $is_free) || ($payment_options|@count === 1 && $module_options|@count === 1)} checked {/if}
              >
              <span></span>
            </span>
            {* This is the way an option should be selected when Javascript is disabled *}
            <form method="GET" class="ps-hidden-by-js">
              {if $option.id === $selected_payment_option}
                {l s='Selected' d='Shop.Theme.Checkout'}
              {else}
                <button class="ps-hidden-by-js" type="submit" name="select_payment_option" value="{$option.id}">
                  {l s='Choose' d='Shop.Theme.Actions'}
                </button>
              {/if}
            </form>

            <label for="{$option.id}">
              <span>{$option.call_to_action_text}</span>
              {if $option.logo}
                <img src="{$option.logo}" loading="lazy">
              {/if}
            </label>

          </div>
        </div>

        {if $option.additionalInformation}
          <div
            id="{$option.id}-additional-information"
            class="js-additional-information definition-list additional-information{if $option.id != $selected_payment_option} ps-hidden {/if}"
          >
            {$option.additionalInformation nofilter}
          </div>
        {/if}

        <div
          id="pay-with-{$option.id}-form"
          class="js-payment-option-form {if $option.id != $selected_payment_option} ps-hidden {/if}"
        >
          {if $option.form}
            {$option.form nofilter}
          {else}
            <form id="payment-{$option.id}-form" method="POST" action="{$option.action nofilter}">
              {foreach from=$option.inputs item=input}
                <input type="{$input.type}" name="{$input.name}" value="{$input.value}">
              {/foreach}
              <button style="display:none" id="pay-with-{$option.id}" type="submit"></button>
            </form>
          {/if}
        </div>
      {/foreach}
    {foreachelse}
      <p class="alert alert-danger">{l s='Unfortunately, there are no payment method available.' d='Shop.Theme.Checkout'}</p>
    {/foreach}
  </div>

  {if $conditions_to_approve|count}
    <p class="ps-hidden-by-js">
      {* At the moment, we're not showing the checkboxes when JS is disabled
         because it makes ensuring they were checked very tricky and overcomplicates
         the template. Might change later.
      *}
      {l s='By confirming the order, you certify that you have read and agree with all of the conditions below:' d='Shop.Theme.Checkout'}
    </p>

    <form id="conditions-to-approve" class="js-conditions-to-approve" method="GET">
      <ul>
        {foreach from=$conditions_to_approve item="condition" key="condition_name"}
          <li>
            <div class="float-xs-left">
              <span class="custom-checkbox">
                <input  id    = "conditions_to_approve[{$condition_name}]"
                        name  = "conditions_to_approve[{$condition_name}]"
                        required
                        type  = "checkbox"
                        value = "1"
                        class = "ps-shown-by-js"
                >
                <span><i class="material-icons rtl-no-flip checkbox-checked">&#xE5CA;</i></span>
              </span>
            </div>
            <div class="condition-label">
              <label class="js-terms" for="conditions_to_approve[{$condition_name}]">
                {$condition nofilter}
              </label>
            </div>
          </li>
        {/foreach}
      </ul>
    </form>
  {/if}

  {hook h='displayCheckoutBeforeConfirmation'}

  {if $show_final_summary}
    {include file='checkout/_partials/order-final-summary.tpl'}
  {/if}

  <div id="payment-confirmation" class="js-payment-confirmation">
    <div class="ps-shown-by-js">
      <button type="submit" class="btn btn-primary center-block{if !$selected_payment_option} disabled{/if}">
        {l s='อัพโหลดสลิป' d='Shop.Theme.Checkout'}
        {hook h='displayExpressCheckout'}
      </button>
      {if $show_final_summary}
        <article class="alert alert-danger mt-2 js-alert-payment-conditions" role="alert" data-alert="danger">
          {l
            s='Please make sure you\'ve chosen a [1]payment method[/1] and accepted the [2]terms and conditions[/2].'
            sprintf=[
              '[1]' => '<a href="#checkout-payment-step">',
              '[/1]' => '</a>',
              '[2]' => '<a href="#conditions-to-approve">',
              '[/2]' => '</a>'
            ]
            d='Shop.Theme.Checkout'
          }
        </article>
      {/if}
    </div>
    <div class="ps-hidden-by-js">
      {if $selected_payment_option and $all_conditions_approved}
        <label for="pay-with-{$selected_payment_option}">{l s='Order with an obligation to pay' d='Shop.Theme.Checkout'}</label>
      {/if}
    </div>
  </div>
  
  {hook h='displayPaymentByBinaries'}

  <script>
    // เมื่อมีการเลือกไฟล์
    document.getElementById('slipFile').addEventListener('change', function() {
        // รับไฟล์ที่ถูกเลือก
        var file = this.files[0];
        // ตรวจสอบว่ามีไฟล์ที่ถูกเลือกหรือไม่
        if (file) {
            // ตรวจสอบนามสกุลของไฟล์
            var fileName = file.name;
            var fileType = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            // ตรวจสอบว่าเป็นไฟล์รูป (.jpg หรือ .png) หรือไม่
            if (fileType === 'jpg' || fileType === 'png') {
                // สร้างฟังก์ชันสำหรับตรวจสอบไฟล์ .jpg ว่ามีตัวอักษรหรือไม่
function checkForText(file) {
  // สร้างอ็อบเจ็กต์ FileReader เพื่ออ่านไฟล์ภาพ
  var reader = new FileReader();

  // เมื่ออ่านไฟล์เสร็จสิ้น
  reader.onload = function(event) {
    // สร้างฟังก์ชันสำหรับตรวจสอบตัวอักษรในภาพ
    function containsText(imageData) {
      // สร้าง Canvas element เพื่อวาดภาพ
      var canvas = document.createElement('canvas');
      var context = canvas.getContext('2d');
      canvas.width = imageData.width;
      canvas.height = imageData.height;
      context.putImageData(imageData, 0, 0);
      
      // ใช้ฟังก์ชัน OCR (Optical Character Recognition) หรือวิธีอื่น ๆ เพื่อตรวจสอบตัวอักษร
      // เพื่อความง่ายในตัวอย่างนี้ ฉันจะแสดงแค่การตรวจสอบความว่างเปล่าของข้อความในภาพ
      var text = context.getImageData(0, 0, canvas.width, canvas.height);
      var isEmpty = true;
      for (var i = 0; i < text.data.length; i += 4) {
        // ตรวจสอบค่าของสีแดง (R) เพื่อดูว่าภาพมีตัวอักษรหรือไม่
        if (text.data[i] !== 255) {
          isEmpty = false;
          break;
        }
      }
      return isEmpty;
    }

    // สร้างภาพในรูปแบบ ImageData
    var img = new Image();
    img.onload = function() {
      var canvas = document.createElement('canvas');
      var context = canvas.getContext('2d');
      canvas.width = img.width;
      canvas.height = img.height;
      context.drawImage(img, 0, 0);
      var imageData = context.getImageData(0, 0, canvas.width, canvas.height);

      // เรียกใช้ฟังก์ชันเพื่อตรวจสอบตัวอักษรในภาพ
      var hasText = containsText(imageData);

      // ตรวจสอบว่าภาพมีตัวอักษรหรือไม่
      if (hasText) {
        alert('ไฟล์ภาพมีตัวอักษร');
      } else {
        alert('ไฟล์ภาพไม่มีตัวอักษร');
        // กระทำเพิ่มเติมเมื่อไม่มีตัวอักษร
      }
    };
    img.src = event.target.result;
  };

  // อ่านไฟล์ภาพเมื่อไฟล์ถูกเลือก
  reader.readAsDataURL(file);
}

// สร้างอินพุตของไฟล์
var fileInput = document.createElement('input');
fileInput.type = 'file';

// เพิ่มการฟังก์ชันสำหรับการเลือกไฟล์
fileInput.addEventListener('change', function(event) {
  var file = event.target.files[0];
  if (file) {
    // เรียกใช้ฟังก์ชันเพื่อตรวจสอบไฟล์
    checkForText(file);
  }
});
                };
                reader.readAsDataURL(file);
            } else {
                // ถ้าไม่ใช่ไฟล์รูป .jpg หรือ .png
                alert("ไฟล์ที่เลือกต้องเป็นรูปภาพเท่านั้น (.jpg หรือ .png)");
                // เคลียร์ input file
                document.getElementById('slipFile').value = "";
            }
        }
    });
  </script>
  

{/block}