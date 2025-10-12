<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kampanyabedava".
 *
 * @property int $id
 * @property int $kampanyaid
 * @property string $stokkodu
 * @property int $minimummiktar
 * @property int $bedavaadet
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class Kampanyabedava extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kampanyabedava';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['kampanyaid', 'stokkodu', 'minimummiktar', 'bedavaadet'], 'required'],
            [['kampanyaid', 'minimummiktar', 'bedavaadet'], 'integer'],
            [['created_at', 'updated_at'], 'safe'],
            [['stokkodu'], 'string', 'max' => 15],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'kampanyaid' => 'Campaign ID',
            'stokkodu' => 'Stock Code',
            'minimummiktar' => 'Minimum Quantity',
            'bedavaadet' => 'Free Quantity',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }
    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['StokKodu' => 'stokkodu']);
    }
}
