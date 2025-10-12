<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "grup".
 *
 * @property int $id
 * @property string|null $grup
 * @property int $aktif
 */
class Grup extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'grup';
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
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'adi' => 'Group',
            'aktif' => 'Active',
        ];
    }

    /**
     * Returns list of active groups for dropdown
     * @return array
     */
    public static function getGrupList()
    {
        return \yii\helpers\ArrayHelper::map(self::find()->where(['aktif' => 1])->all(), 'id', 'adi');
    }

}
