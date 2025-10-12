<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kampanya".
 *
 * @property int $id
 * @property int $tur
 * @property string $baslamazamani
 * @property string $bitiszamani
 * @property string $baslik
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property int $userid
 */
class Kampanya extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kampanya';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['tur', 'baslamazamani', 'bitiszamani', 'baslik', 'userid'], 'required'],
            [['tur', 'userid','id'], 'integer'],
            [['baslamazamani', 'bitiszamani', 'created_at', 'updated_at'], 'safe'],
            [['baslik'], 'string', 'max' => 255],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'tur' => 'Campaign Type',
            'baslamazamani' => 'Start Time',
            'bitiszamani' => 'End Time',
            'baslik' => 'Title',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'userid' => 'User ID',
        ];
    }

    public function getBedavalar()
    {
        return $this->hasMany(Kampanyabedava::class, ['kampanyaid' => 'id']);
    }
    public function getIndirimler()
    {
        return $this->hasMany(Kampanyaindirim::class, ['kampanyaid' => 'id']);
    }

    public function getToplamindirimler()
    {
        return $this->hasMany(Fiseindirimkampanyalari::class, ['kampanyaid' => 'id']);
    }
}
