<?php

namespace app\models;

use Yii;
use yii\base\Model;

/**
 * LoginForm is the model behind the login form.
 *
 * @property GlobalIdentity|null $identity This property is read-only.
 *
 */
class LoginForm extends Model
{
    public $username;
    public $password;
    public $rememberMe = true;

    private $_identity = false;


    /**
     * @return array the validation rules.
     */
    public function rules()
    {
        return [
            // username and password are both required
            [['username', 'password'], 'required'],
            // rememberMe must be a boolean value
            ['rememberMe', 'boolean'],
            // password is validated by validatePassword()
            ['password', 'validatePassword'],
        ];
    }

    /**
     * Validates the password.
     * This method serves as the inline validation for password.
     *
     * @param string $attribute the attribute currently being validated
     * @param array $params the additional name-value pairs given in the rule
     */
    public function validatePassword($attribute, $params)
    {
        if (!$this->hasErrors()) {
            $identity = $this->getIdentity();
            
            if (!$identity || !$identity->validatePassword($this->password)) {
                $this->addError($attribute, 'Kullanıcı adı veya şifre hatalı.');
            }
        }
    }

    /**
     * Logs in a user using the provided username and password.
     * @return bool whether the user is logged in successfully
     */
    public function login()
    {
        if ($this->validate()) {
            return Yii::$app->user->login($this->getIdentity(), $this->rememberMe ? 3600 : 0);
        }
        return false;
    }

    /**
     * Finds identity by [[username]]
     *
     * @return GlobalIdentity|null
     */
    public function getIdentity()
    {
        if ($this->_identity === false) {
            $this->_identity = GlobalIdentity::findByUsername($this->username);
        }

        return $this->_identity;
    }
}
