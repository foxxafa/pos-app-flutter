<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "musteriler".
 *
 * @property int $MusteriId
 * @property string $Unvan
 * @property string|null $VergiNo
 * @property string|null $VergiDairesi
 * @property string|null $anaadreskey
 * @property string|null $Adres
 * @property string|null $Telefon
 * @property string|null $Email
 * @property string|null $Kod
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property string|null $postcode
 * @property int|null $Aktif
 * @property float|null $bakiye
 * @property string|null $city
 * @property string|null $contact
 * @property string|null $mobile
 * @property string|null $_key
 * @property string|null $satiselemani
 * @property string|null $EOID
 * @property string|null $FID
 */
class Musteriler extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'musteriler';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['VergiNo', 'VergiDairesi', 'anaadreskey', 'Adres', 'Telefon', 'Email', 'Kod', 'created_at', 'updated_at', 'postcode', 'city', 'contact', 'mobile', '_key', 'satiselemani', 'EOID', 'FID'], 'default', 'value' => null],
            [['Unvan'], 'required'],
            [['Aktif'], 'integer'],
            [['bakiye'], 'number'],
            [['Adres'], 'string'],
            [['Unvan', 'VergiDairesi', 'Email', 'EOID', 'FID'], 'string', 'max' => 255],
            [['VergiNo'], 'string', 'max' => 20],
            [['Telefon'], 'string', 'max' => 85],
            [['postcode'], 'string', 'max' => 15],
            [['Kod', 'anaadreskey', 'satiselemani'], 'string', 'max' => 50],
            [['city', 'contact', 'mobile', '_key'], 'string', 'max' => 45],
            [['created_at', 'updated_at'], 'safe'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'MusteriId' => 'Customer ID',
            'Unvan' => 'Customer',
            'VergiNo' => 'Tax No',
            'VergiDairesi' => 'Tax Office',
            'anaadreskey' => 'Main Address Key',
            'Adres' => 'Address',
            'Telefon' => 'Phone',
            'Email' => 'Email',
            'Kod' => 'Code',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'postcode' => 'Post Code',
            'Aktif' => 'Active',
            'bakiye' => 'Balance',
            'city' => 'City',
            'contact' => 'Contact',
            'mobile' => 'Mobile',
            '_key' => 'Key',
            'satiselemani' => 'Sales Element',
            'EOID' => 'EOID',
            'FID' => 'FID'
        ];
    }

    public function getSatisfisler(){
        return $this->hasMany(Satisfisleri::className(), ['MusteriId' => 'Kod']);
    }

}
