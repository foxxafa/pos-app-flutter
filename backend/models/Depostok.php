<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "depostok".
 *
 * @property int $id
 * @property string $StokKodu
 * @property int $warehouse_key
 * @property float $miktar
 * @property string $birim
 */
class Depostok extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'depostok';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['miktar'], 'default', 'value' => 0.00],
            [['StokKodu', 'warehouse_key', 'birim'], 'required'],
            [['warehouse_key'], 'integer'],
            [['miktar'], 'number'],
            [['StokKodu', 'birim'], 'string', 'max' => 45],
            [['StokKodu', 'warehouse_key'], 'unique', 'targetAttribute' => ['StokKodu', 'warehouse_key'], 'message' => 'Bu stok kodu ve depo anahtarı kombinasyonu zaten mevcut.'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'StokKodu' => 'Stok Kodu',
            'warehouse_key' => 'Warehouse Key',
            'miktar' => 'Miktar',
            'birim' => 'Birim',
        ];
    }

}
