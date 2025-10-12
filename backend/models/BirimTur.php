<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "birim_tur".
 *
 * @property string $BirimKodu
 * @property string|null $BirimAdi
 */
class BirimTur extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'birim_tur';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['BirimAdi'], 'default', 'value' => null],
            [['BirimKodu'], 'required'],
            [['BirimKodu'], 'string', 'max' => 20],
            [['BirimAdi'], 'string', 'max' => 50],
            [['BirimKodu'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'BirimKodu' => 'Birim Kodu',
            'BirimAdi' => 'Birim Adi',
        ];
    }

    public static function getBirimler(){
        return BirimTur::find()->all();
    }

}
