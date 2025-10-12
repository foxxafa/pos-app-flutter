<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "satinalma_tedarikcifis".
 *
 * @property int $id
 * @property int $siparis_id
 * @property int $tedarikci_id
 * @property int $durum
 * @property string|null $fisno
 */
class SatinalmaTedarikcifis extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satinalma_tedarikcifis';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_id', 'tedarikci_id', 'durum'], 'required'],
            [['siparis_id', 'tedarikci_id', 'durum'], 'integer'],
            [['fisno'], 'string', 'max' => 50],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'siparis_id' => 'Order ID',
            'tedarikci_id' => 'Supplier ID',
            'durum' => 'Status',
            'fisno' => 'Fiş No',
        ];
    }

    public function getSatinAlmaSiparisFisSatirs()
    {
        return $this->hasMany(SatinAlmaSiparisFisSatir::class, ['tedarikci_fis_id' => 'id']);
    }
    
    public function getTedarikci()
    {
        return $this->hasOne(Tedarikci::class, ['id' => 'tedarikci_id']);
    }
    public function getSatinalmasiparisfis()
    {
        return $this->hasOne(SatinAlmaSiparisFis::class, ['id' => 'siparis_id']);
    }
}
