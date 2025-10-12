<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "tedarikci".
 *
 * @property int $id
 * @property string|null $tedarikci_kodu
 * @property string|null $tedarikci_adi
 * @property int|null $user
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property string|null $_key
 * @property int|null $Aktif
 *
 * @property SiparisTedarikciMapping[] $siparisTedarikciMappings
 */
class Tedarikci extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'tedarikci';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['tedarikci_kodu', 'tedarikci_adi', 'user', '_key'], 'default', 'value' => null],
            [['user','Aktif'], 'integer'],
            [['created_at', 'updated_at'], 'safe'],
            [['tedarikci_kodu', 'tedarikci_adi'], 'string', 'max' => 255],
            [['_key'], 'string', 'max' => 15],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'tedarikci_kodu' => 'Supplier Code',
            'tedarikci_adi' => 'Supplier Name',
            'user' => 'User',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            '_key' => 'Key',
            'Aktif' => 'Aktif',
        ];
    }

    /**
     * Gets query for [[SiparisTedarikciMappings]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSiparisTedarikciMappings()
    {
        return $this->hasMany(SiparisTedarikciMapping::class, ['tedarikci_id' => 'id']);
    }
    public static function getTedarikciList(){
        return self::find()->all();
    }
    public static function getTedarikciListByCode(){
        return \yii\helpers\ArrayHelper::map(self::find()->all(), 'tedarikci_kodu', 'tedarikci_adi');
    }
    public static function getTedarikciListById(){
        return \yii\helpers\ArrayHelper::map(self::find()->all(), 'id', 'tedarikci_adi');
    }
}
