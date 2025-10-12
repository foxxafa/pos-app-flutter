<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "markalar".
 *
 * @property int $id
 * @property string|null $marka
 * @property int $aktif
 */
class Marka extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'marka';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['adi'], 'default', 'value' => null],
            [['aktif'], 'default', 'value' => 1],
            [['aktif'], 'integer'],
            [['adi'], 'string', 'max' => 120],
            [['_key'], 'string', 'max' => 15],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'adi' => 'Brand',
            'aktif' => 'Active',
            '_key' => 'Key',
        ];
    }

    /**
     * Returns list of active brands for dropdown
     * @return array
     */
    public static function getMarkaList()
    {
        return \yii\helpers\ArrayHelper::map(self::find()->where(['aktif' => 1])->all(), 'id', 'adi');
    }

}
