<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "containers".
 *
 * @property int $id
 * @property string|null $type
 * @property int|null $plt_qty
 * @property string|null $plt_typ
 * @property float|null $volume
 */
class Containers extends \yii\db\ActiveRecord
{

    const PALLET_TYPE_STN = 'STN';
    const PALLET_TYPE_EUR = 'EUR';

    public static function getPalletTypes()
    {
        return [
            self::PALLET_TYPE_STN => 'STN',
            self::PALLET_TYPE_EUR => 'EUR',
        ];
    }


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'containers';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['type', 'plt_qty', 'plt_typ', 'volume'], 'default', 'value' => null],
            [['plt_qty'], 'integer'],
            [['volume'], 'number'],
            [['type'], 'string', 'max' => 20],
            ['plt_typ', 'in', 'range' => array_keys(self::getPalletTypes())],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'type' => 'Type',
            'plt_qty' => 'Palet Qty',
            'plt_typ' => 'Palet Type',
            'volume' => 'Volume',
        ];
    }

}
