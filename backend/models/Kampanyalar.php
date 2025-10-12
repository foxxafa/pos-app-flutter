<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kampanyalar".
 *
 * @property int $id
 * @property string|null $kampanyaadi
 * @property string|null $baslamazamani
 * @property string|null $bitiszamani
 * @property string|null $kayitzamani
 * @property int|null $_key
 */
class Kampanyalar extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kampanyalar';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['kampanyaadi', 'baslamazamani', 'bitiszamani', 'islemzamani', '_key'], 'default', 'value' => null],
            [['id', '_key'], 'integer'],
            [['baslamazamani', 'bitiszamani', 'islemzamani'], 'safe'],
            [['kampanyaadi'], 'string', 'max' => 120],
            [['_key'], 'unique'],
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
            'kampanyaadi' => 'Kampanyaadi',
            'baslamazamani' => 'Baslamazamani',
            'bitiszamani' => 'Bitiszamani',
            'kayitzamani' => 'Kayitzamani',
            '_key' => 'Key',
        ];
    }

}
