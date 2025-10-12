<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "uruntedarikci".
 *
 * @property int $id
 * @property string|null $stokkodu
 * @property string|null $tedarikcikodu
 * @property float|null $sonfiyat
 * @property string|null $sonislemzamani
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property string|null $tedarikciad
 */
class UrunTedarikci extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'uruntedarikci';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['stokkodu', 'tedarikcikodu', 'sonfiyat', 'sonislemzamani'], 'default', 'value' => null],
            [['sonfiyat'], 'number'],
            [['sonislemzamani', 'created_at', 'updated_at'], 'safe'],
            [['stokkodu', 'tedarikcikodu'], 'string', 'max' => 20],
            [['tedarikcikodu'], 'required'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'stokkodu' => 'Stokkodu',
            'tedarikcikodu' => 'Tedarikcikodu',
            'sonfiyat' => 'Sonfiyat',
            'sonislemzamani' => 'Sonislemzamani',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    public function getTedarikci()
    {
        return $this->hasOne(Tedarikci::class, ['tedarikci_kodu' => 'tedarikcikodu']);
    }

}
