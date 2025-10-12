<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kampanyaindirim".
 *
 * @property int $id
 * @property int $kampanyaid
 * @property string $stokkodu
 * @property float $minimumtutar
 * @property int $indirimorani
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class Kampanyaindirim extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kampanyaindirim';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['kampanyaid', 'stokkodu', 'minimummiktar', 'indirimorani'], 'required'],
            [['kampanyaid', 'indirimorani'], 'integer'],
            [['minimummiktar'], 'number'],
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
            'indirimorani' => 'Discount Rate',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }
    public function getUrun(){
        return $this->hasOne(Urunler::class, ['StokKodu' => 'stokkodu']);
    }
}
