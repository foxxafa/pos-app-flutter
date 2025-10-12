<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "birimler".
 *
 * @property int $id
 * @property string|null $birimadi
 * @property string|null $birimkod
 * @property float|null $carpan
 * @property float|null $fiyat1
 * @property float|null $fiyat2
 * @property float|null $fiyat3
 * @property float|null $fiyat4
 * @property float|null $fiyat5
 * @property float|null $fiyat6
 * @property float|null $fiyat7
 * @property float|null $fiyat8
 * @property float|null $fiyat9
 * @property float|null $fiyat10
 * @property string|null $_key
 * @property string|null $_key_scf_stokkart
 * @property string|null $StokKodu
 * 
 * @property Urunler $urun
 * @property Barkodlar[] $barkodlar
 */
class Birimler extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'birimler';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['_key'], 'unique'],
            [['carpan', 'fiyat1', 'fiyat2', 'fiyat3', 'fiyat4', 'fiyat5', 'fiyat6', 'fiyat7', 'fiyat8', 'fiyat9', 'fiyat10'], 'number'],
            [['birimadi', 'birimkod'], 'string', 'max' => 20],
            [['_key', '_key_scf_stokkart', 'StokKodu'], 'string', 'max' => 45],
            [['StokKodu'], 'exist', 'skipOnError' => true, 'targetClass' => Urunler::class, 'targetAttribute' => ['StokKodu' => 'StokKodu']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'birimadi' => 'Birim Adı',
            'birimkod' => 'Birim Kodu',
            'carpan' => 'Çarpan',
            'fiyat1' => 'Fiyat 1',
            'fiyat2' => 'Fiyat 2',
            'fiyat3' => 'Fiyat 3',
            'fiyat4' => 'Fiyat 4',
            'fiyat5' => 'Fiyat 5',
            'fiyat6' => 'Fiyat 6',
            'fiyat7' => 'Fiyat 7',
            'fiyat8' => 'Fiyat 8',
            'fiyat9' => 'Fiyat 9',
            'fiyat10' => 'Fiyat 10',
            '_key' => 'Key',
            '_key_scf_stokkart' => 'Key Scf Stokkart',
            'StokKodu' => 'Stok Kodu',
        ];
    }

    /**
     * Gets query for [[Urun]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['StokKodu' => 'StokKodu']);
    }

    /**
     * Gets query for [[Barkodlar]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getBarkodlar()
    {
        return $this->hasMany(Barkodlar::class, ['_key_scf_stokkart_birimleri' => '_key']);
    }
}
