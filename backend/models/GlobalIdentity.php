<?php

namespace app\models;

use Yii;
use yii\web\IdentityInterface;

/**
 * GlobalIdentity sınıfı, hem User hem de Employees kimlik doğrulamasını yöneten bir sarmalayıcıdır
 */
class GlobalIdentity implements IdentityInterface
{
    /**
     * @var IdentityInterface User veya Employees kimliği
     */
    private $_identity;

    /**
     * GlobalIdentity constructor
     * 
     * @param IdentityInterface $identity Temel kimlik
     */
    public function __construct($identity = null)
    {
        $this->_identity = $identity;
    }

    /**
     * {@inheritdoc}
     */
    public static function findIdentity($id)
    {
        // Önce User modelinde arama yapalım
        $user = User::findIdentity($id);
        if ($user !== null) {
            return new self($user);
        }

        // Bulunamazsa Employees modelinde arama yapalım
        $employee = Employees::findIdentity($id);
        if ($employee !== null) {
            return new self($employee);
        }

        return null;
    }

    /**
     * {@inheritdoc}
     */
    public static function findIdentityByAccessToken($token, $type = null)
    {
        // Önce User modelinde arama yapalım
        $user = User::findIdentityByAccessToken($token, $type);
        if ($user !== null) {
            return new self($user);
        }

        // Bulunamazsa Employees modelinde arama yapalım
        $employee = Employees::findIdentityByAccessToken($token, $type);
        if ($employee !== null) {
            return new self($employee);
        }

        return null;
    }

    /**
     * Kullanıcı adına göre kimlik bulur
     * 
     * @param string $username Kullanıcı adı
     * @return static|null
     */
    public static function findByUsername($username)
    {
        // Önce User modelinde arama yapalım
        $user = User::findByUsername($username);
        if ($user !== null) {
            return new self($user);
        }

        // Bulunamazsa Employees modelinde arama yapalım
        $employee = Employees::findByUsername($username);
        if ($employee !== null) {
            return new self($employee);
        }

        return null;
    }

    /**
     * {@inheritdoc}
     */
    public function getId()
    {
        return $this->_identity ? $this->_identity->getId() : null;
    }

    /**
     * {@inheritdoc}
     */
    public function getAuthKey()
    {
        return $this->_identity ? $this->_identity->getAuthKey() : null;
    }

    /**
     * {@inheritdoc}
     */
    public function validateAuthKey($authKey)
    {
        return $this->_identity ? $this->_identity->validateAuthKey($authKey) : false;
    }

    /**
     * Şifreyi doğrular
     * 
     * @param string $password Şifre
     * @return bool Şifre doğru mu
     */
    public function validatePassword($password)
    {
        return $this->_identity ? $this->_identity->validatePassword($password) : false;
    }

    /**
     * Temel kimliği döndürür (User veya Employees)
     * 
     * @return IdentityInterface|null
     */
    public function getIdentity()
    {
        return $this->_identity;
    }

    /**
     * Kimlik tipini döndürür
     * 
     * @return string 'user' veya 'employee'
     */
    public function getType()
    {
        if ($this->_identity instanceof User) {
            return 'user';
        } elseif ($this->_identity instanceof Employees) {
            return 'employee';
        }
        
        return null;
    }

    /**
     * Magic method for accessing properties of the underlying identity
     */
    public function __get($name)
    {
        if ($this->_identity) {
            // Önce property_exists ile kontrol et
            if (property_exists($this->_identity, $name)) {
                return $this->_identity->$name;
            }
            
            // Getter metodu da olabilir: getXxx() şeklinde
            $getter = 'get' . ucfirst($name);
            if (method_exists($this->_identity, $getter)) {
                return $this->_identity->$getter();
            }
        }
        
        // Özel durum: 'role' için User modelinde 'tur' alanını kontrol et
        if ($name === 'role' && $this->_identity instanceof \app\models\User) {
            return $this->_identity->tur;
        }
        
        return null;
    }
}
