<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kampanyafiyatlari".
 *
 * @property int $id
 * @property string|null $islemzamani
 * @property string|null $baslamazamani
 * @property string|null $bitiszamani
 * @property float|null $fiyat
 * @property float|null $yenifiyat
 * @property string|null $birim
 * @property int|null $aktif
 * @property string|null $kampanyaadi
 * @property int|null $kampanyaid
 * @property string|null $stokkodu
 */
class Kampanyafiyatlari extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kampanyafiyatlari';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['islemzamani', 'baslamazamani', 'bitiszamani', 'fiyat', 'yenifiyat', 'birim', 'kampanyaadi', 'kampanyaid', 'stokkodu'], 'default', 'value' => null],
            [['aktif'], 'default', 'value' => 0],
            [['_key'], 'required'],
            [['id', 'aktif', 'kampanyaid','_key'], 'integer'],
            [['islemzamani', 'baslamazamani', 'bitiszamani'], 'safe'],
            [['fiyat', 'yenifiyat'], 'number'],
            [['birim', 'stokkodu'], 'string', 'max' => 45],
            [['kampanyaadi'], 'string', 'max' => 120],
            [['id'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'islemzamani' => 'Islemzamani',
            'baslamazamani' => 'Baslamazamani',
            'bitiszamani' => 'Bitiszamani',
            'fiyat' => 'Fiyat',
            'yenifiyat' => 'Yenifiyat',
            'birim' => 'Birim',
            'aktif' => 'Aktif',
            'kampanyaadi' => 'Kampanyaadi',
            'kampanyaid' => 'Kampanyaid',
            'stokkodu' => 'Stokkodu',
        ];
    }

}
