<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "user".
 *
 * @property string $username
 * @property string|null $password
 * @property string|null $isim
 * @property int|null $tur
 * @property int|null $subeid
 * @property int $id
 */
class User extends  \yii\db\ActiveRecord implements \yii\web\IdentityInterface
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'user';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['password', 'isim', 'tur', 'subeid'], 'default', 'value' => null],
            [['username'], 'required'],
            [['tur', 'subeid','aktif'], 'integer'],
            [['username', 'password', 'isim','authKey'], 'string', 'max' => 45],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'username' => 'Username',
            'password' => 'Password',
            'isim' => 'Name',
            'tur' => 'Type',
            'subeid' => 'Subeid',
            'id' => 'ID',
        ];
    }
    public static function findIdentity($id){
        return static::findOne($id);
    }
    public static function findIdentityByAccessToken($token, $type = null){
        throw new NotSupportedException();//I don't implement this method because I don't have any access token column in my database
    }
    public function getAuthKey(){
        return $this->authKey;//Here I return a value of my authKey column
    }
    public function validateAuthKey($authKey){
        return $this->authKey === $authKey;
    }
    public static function findByUsername($username){
        return self::findOne(['username'=>$username]);
    }

    public function getId()
    {
        return $this->id;
    }

    public function validatePassword($password)
    {
        return ($this->password === $password && $this->aktif==1);
    }
}
