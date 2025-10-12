<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "tedarikci_siparis_fis".
 *
 * @property int $id
 * @property string|null $stok_kodu
 * @property float|null $miktar
 * @property int|null $tedarikci_id
 * @property string|null $tarih
 * @property string|null $user
 * @property string|null $created_at
 * @property string|null $updated_at
 *
 * @property SatinAlmaSiparisFisSatir[] $satinAlmaSiparisFisSatirs
 */
class TedarikciSiparisFis extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'tedarikci_siparis_fis';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['stok_kodu', 'miktar', 'tedarikci_id', 'tarih', 'user'], 'default', 'value' => null],
            [['miktar'], 'number'],
            [['tedarikci_id'], 'integer'],
            [['tarih', 'created_at', 'updated_at'], 'safe'],
            [['stok_kodu', 'user'], 'string', 'max' => 255],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'stok_kodu' => 'Stock Kodu',
            'miktar' => 'Qty',
            'tedarikci_id' => 'Supplier ID',
            'tarih' => 'Date',
            'user' => 'User',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    /**
     * Gets query for [[SatinAlmaSiparisFisSatirs]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSatinAlmaSiparisFisSatirs()
    {
        return $this->hasMany(SatinAlmaSiparisFisSatir::class, ['tedarikci_fis_id' => 'id']);
    }

}
