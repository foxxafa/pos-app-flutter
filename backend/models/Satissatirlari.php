<?php

namespace app\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;

/**
 * This is the model class for table "satissatirlari".
 *
 * @property int $SatissatirId
 * @property string $FisNo
 * @property int $UrunId
 * @property float $Miktar
 * @property float $BirimFiyat
 * @property float $ToplamTutar
 * @property float|null $vat
 * @property string|null $BirimTipi
 * @property string|null $Durum
 * @property string|null $UrunBarcode
 * @property int|null $SyncStatus
 * @property string|null $LastSyncTime
 * @property string|null $created_at
 * @property string|null $updated_at
 *
 * @property Satisfisleri $fisNo
 */
class Satissatirlari extends \yii\db\ActiveRecord
{
    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'createdAtAttribute' => 'created_at',
                'updatedAtAttribute' => 'updated_at',
                'value' => new Expression('NOW()'),
            ],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satissatirlari';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['vat', 'BirimTipi',  'UrunBarcode', 'LastSyncTime'], 'default', 'value' => null],
            [['SyncStatus'], 'default', 'value' => 0],
            [['FisNo', 'StokKodu', 'Miktar', 'BirimFiyat', 'ToplamTutar'], 'required'],
            [[ 'SyncStatus','Iskonto','Durum'], 'integer'],
            [['Miktar', 'BirimFiyat', 'ToplamTutar', 'vat','hmrckontrol'], 'number'],
            [['LastSyncTime', 'created_at', 'updated_at', 'tarih'], 'safe'],
            [['FisNo','StokKodu','satispersoneli'], 'string', 'max' => 40],
            [['BirimTipi'], 'string', 'max' => 20],
            [['comment'], 'string', 'max' => 250],
            [['UrunBarcode'], 'string', 'max' => 50]
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'SatisSatirId' => 'Sale Line ID',
            'FisNo' => 'Receipt Number',
            'StokKodu' => 'Stock Code',
            'Miktar' => 'Quantity',
            'BirimFiyat' => 'Unit Price',
            'ToplamTutar' => 'Total Amount',
            'vat' => 'VAT',
            'BirimTipi' => 'Unit Type',
            'Durum' => 'Status',
            'UrunBarcode' => 'Product Barcode',
            'SyncStatus' => 'Sync Status',
            'LastSyncTime' => 'Last Sync Time',
            'Iskonto' => 'Discount',
            'hmrckontrol' => 'HMRC Control',
            'tarih' => 'Tarih',
            'created_at' => 'Oluşturulma Zamanı',
            'updated_at' => 'Güncellenme Zamanı',
        ];
    }

    /**
     * Gets query for [[FisNo]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getFisNo()
    {
        return $this->hasOne(Satisfisleri::class, ['FisNo' => 'FisNo']);
    }

}
