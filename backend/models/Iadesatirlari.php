<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "iadesatirlari".
 *
 * @property int $IadesatirId
 * @property string|null $FisNo
 * @property string|null $StokKodu
 * @property float|null $Miktar
 * @property float|null $BirimFiyat
 * @property float|null $ToplamTutar
 * @property int|null $vat
 * @property string|null $BirimTipi
 * @property int|null $Durum
 * @property string|null $UrunBarcode
 * @property int|null $SyncStatus
 * @property string|null $LastSyncTime
 * @property int|null $Iskonto
 * @property int|null $hmrckontrol
 * @property string|null $tarih
 */
class Iadesatirlari extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'iadesatirlari';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['FisNo', 'StokKodu', 'Miktar', 'BirimFiyat', 'ToplamTutar', 'vat', 'BirimTipi', 'UrunBarcode', 'LastSyncTime', 'tarih'], 'default', 'value' => null],
            [['Durum'], 'default', 'value' => 1],
            [['hmrckontrol'], 'default', 'value' => 0],
            [['Miktar', 'BirimFiyat', 'ToplamTutar'], 'number'],
            [['vat', 'Durum', 'SyncStatus', 'Iskonto', 'hmrckontrol'], 'integer'],
            [['LastSyncTime', 'tarih'], 'safe'],
            [['FisNo'], 'string', 'max' => 40],
            [['StokKodu'], 'string', 'max' => 30],
            [['aciklama'], 'string', 'max' => 250],
            [['BirimTipi', 'UrunBarcode'], 'string', 'max' => 50],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'IadesatirId' => 'Iadesatir ID',
            'FisNo' => 'Receipt No',
            'StokKodu' => 'Stock Kodu',
            'Miktar' => 'Qty',
            'BirimFiyat' => 'Qty Price',
            'ToplamTutar' => 'Total Amount',
            'vat' => 'Vat',
            'BirimTipi' => 'Unit Type',
            'Durum' => 'Status',
            'UrunBarcode' => 'Product Barcode',
            'SyncStatus' => 'Sync Status',
            'LastSyncTime' => 'Last Sync Time',
            'Iskonto' => 'Discount',
            'hmrckontrol' => 'HmrcControl',
            'tarih' => 'Date',
        ];
    }

}
