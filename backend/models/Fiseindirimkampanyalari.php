<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "fiseindirimkampanyalari".
 *
 * @property int $id
 * @property int $kampanyaid
 * @property float $fistutarimin
 * @property float $indirimmiktari
 * @property int $aktif
 * @property string $created_at
 * @property string $updated_at
 */
class Fiseindirimkampanyalari extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'fiseindirimkampanyalari';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['indirimmiktari'], 'default', 'value' => 0.00],
            [['aktif'], 'default', 'value' => 1],
            [['kampanyaid'], 'required'],
            [['kampanyaid', 'aktif'], 'integer'],
            [['fistutarimin', 'indirimmiktari'], 'number'],
            [['created_at', 'updated_at'], 'safe'],
            [['name'],'string', 'max' => 45]
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'kampanyaid' => 'Kampanyaid',
            'fistutarimin' => 'Fistutarimin',
            'indirimmiktari' => 'Indirimmiktari',
            'aktif' => 'Aktif',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

}
