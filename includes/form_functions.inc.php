<?php
function create_form_input($name, $type, $errors = array(), $values = 'POST', $options = array()) {
    $value = false;
    if ($values === 'SESSION') {
        if (isset($_SESSION[$name])) $value = htmlspecialchars($_SESSION[$name], ENT_QUOTES, 'UTF-8');
    } elseif ($values === 'POST') {
        if (isset($_POST[$name])) $value = htmlspecialchars($_POST[$name], ENT_QUOTES, 'UTF-8');
        if ($value && get_magic_quotes_gpc()) $value = stripslashes($value);
    }

    if ( ($type === 'text') || ($type === 'password') ) {
    	echo '<input type="' . $type . '" name="' . $name . '" id="' . $name . '"';
        if ($value) echo ' value="' . $value . '"';
        if (!empty($options) && is_array($options)) {
            foreach ($options as $k => $v) {
                echo " $k=\"$v\"";
            }
        }
        if (array_key_exists($name, $errors)) {
            echo 'class="error" /> <span class="error">' . $errors[$name] . '</span>';
        } else {
            echo ' />';
        }
    } elseif ($type === 'select') {
    	if (($name === 'state') || ($name === 'cc_state')) {
            $data = array('AL' => 'Alabama', 'AK' => 'Alaska', 'AZ' => 'Arizona', 'AR' =>
            'Arkansas', 'CA' => 'California', 'CO' => 'Colorado', 'CT' => 'Connecticut', 'DE' =>
            'Delaware', 'FL' => 'Florida', 'GA' => 'Georgia', 'HI' => 'Hawaii', 'ID' => 'Idaho',
            'IL' => 'Illinois', 'IN' => 'Indiana', 'IA' => 'Iowa', 'KS' => 'Kansas', 'KY' =>
            'Kentucky', 'LA' => 'Louisiana', 'ME' => 'Maine', 'MD' => 'Maryland', 'MA' =>
            'Massachusetts', 'MI' => 'Michigan', 'MN' => 'Minnesota', 'MS' => 'Mississippi',
            'MO' => 'Missouri', 'MT' => 'Montana', 'NE' => 'Nebraska', 'NV' => 'Nevada', 'NH' =>
            'New Hampshire', 'NJ' => 'New Jersey', 'NM' => 'New Mexico', 'NY' => 'New York',
            'NC' => 'North Carolina', 'ND' => 'North Dakota', 'OH' => 'Ohio', 'OK' =>
            'Oklahoma', 'OR' => 'Oregon', 'PA' => 'Pennsylvania', 'RI' => 'Rhode Island', 'SC'
            => 'South Carolina', 'SD' => 'South Dakota', 'TN' => 'Tennessee', 'TX' => 'Texas',
            'UT' => 'Utah', 'VT' => 'Vermont', 'VA' => 'Virginia', 'WA' => 'Washington', 'WV' =>
            'West Virginia', 'WI' => 'Wisconsin', 'WY' => 'Wyoming');
        } elseif ($name === 'cc_exp_month') {
            $data = array(1 => 'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August',  'September', 'October', 'November', 'December');
        } elseif ($name === 'cc_exp_year') {
            $data = array();
            $start = date('Y');
            for ($i = $start; $i <= $start + 5; $i++) {
                $data[$i] = $i;
            }
        } // End of $name IF-ELSEIF.

        echo '<select name="' . $name  . '"';

        if (array_key_exists($name, $errors)) echo ' class="error"';
        echo '>';

        foreach ($data as $k => $v) {
            echo "<option value=\"$k\"";
            if ($value === $k) echo ' selected="selected"';
            echo ">$v</option>\n";
        }

        if (array_key_exists($name, $errors)) {
            echo '<br /><span class="error">' . $errors[$name] . '</span>';
        }
    } // End of primary IF-ELSE.
    elseif ($type === 'textarea') {
        if (array_key_exists($name, $errors)) echo ' <span class="error">' . $errors[$name] . '</span><br />';
        echo '<textarea name="' . $name . '" id="' . $name . '" rows="5" cols="75"';
        if (array_key_exists($name, $errors)) {
            echo ' class="error">';
        } else {
            echo '>';
        }
        if ($value) echo $value;
        echo '</textarea>';
    }
} // End of the create_form_input() function.